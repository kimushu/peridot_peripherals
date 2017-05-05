#include "peridot_swi.h"
#include <errno.h>
#include <string.h>

enum {
  CMD_PAGE_PROGRAM = 0x02,
  CMD_READ_BYTES   = 0x03,
  CMD_READ_STATUS  = 0x05,
  CMD_WRITE_ENABLE = 0x06,
  CMD_READ_SFDP    = 0x5a,
  CMD_READ_JEDECID = 0x9f,
  CMD_READ_DEVID   = 0xab,
};

/**
 * Fast divide by 2^N
 */
static int div_power2(int numerator, unsigned int denominator)
{
  if (denominator == 0) {
    return -1;
  }

  for (; (denominator & 1) == 0; denominator >>= 1) {
    numerator /= 2;
  }

  return numerator;
}

/**
 * Read SFDP data
 */
static int peridot_swi_flash_read_sfdp(alt_u8 address, void *buffer, int length)
{
  alt_u8 cmd[] = {CMD_READ_SFDP, 0x00, 0x00, address, 0x00};
  if (peridot_swi_flash_command(sizeof(cmd), cmd, length, buffer, 0) != length) {
    return -EIO;
  }
  return length;
}

/**
 * Search SDFP Basic table offset
 */
static int peridot_swi_flash_search_sfdp_table(alt_u8 id_lsb, alt_u8 id_msb)
{
  int result;
  alt_u32 buf[2];
  int num_params;
  int index;

  result = peridot_swi_flash_read_sfdp(0x00, buf, sizeof(buf));
  if (result < 0) {
    return result;
  }

  if (buf[0] != 0x50444653 || (buf[1] & 0xffff) < 0x0106) {
    // Device does not support SFDP version 01.06 (JEDEC JESD216 RevB)
    return -ENOTSUP;
  }
  num_params = (buf[1] >> 16) & 0xff;

  // Search JEDEC SFDP table
  for (index = 1; index <= num_params; ++index) {
    result = peridot_swi_flash_read_sfdp(index * sizeof(buf), buf, sizeof(buf));
    if (result < 0) {
      return result;
    }

    if ((buf[0] & 0xff) == id_lsb && (buf[1] >> 24) == id_msb) {
      // Found
      return (buf[1] & 0xff);
    }
  }
  return -ENOTSUP;
}

/**
 * Query device information by JEDEC SFDP structure
 */
static int peridot_swi_flash_query_sfdp(peridot_swi_flash_dev *dev)
{
  int result;
  flash_region *region;
  alt_u32 basic[16];
  int index;

  // Search SFDP Basic flash table
  result = peridot_swi_flash_search_sfdp_table(0x00, 0xff);
  if (result < 0) {
    return result;
  }

  // Read SFDP Basic flash table
  result = peridot_swi_flash_read_sfdp(result, basic, sizeof(basic));
  if (result < 0) {
    return result;
  }

  region = &dev->dev.region_info[0];
  region->offset = 0;

  // Check 4-byte addressing mode
  dev->four_bytes_mode = (((basic[0] >> 17) & 3) == 2);

  // Get write page size
  dev->page_size = 1u << ((basic[10] >> 4) & 0xf);

  // Get total capacity
  if (basic[1] & 0x80000000) {
    region->region_size = 1u << ((basic[1] & 0x7fffffff) - 3);
  } else {
    region->region_size = (basic[1] >> 3) + 1;
  }

  // Get smallest erase size & instruction
  region->block_size = ~0;
  for (index = 0; index < 4; ++index) {
    alt_u16 data = ((alt_u16 *)&basic[7])[index];
    alt_u8 shift = data & 0xff;
    alt_u32 size = 1u << shift;
    if ((shift > 0) && (size < region->block_size)) {
      region->block_size = size;
      dev->erase_inst = data >> 8;
    }
  }
  if (region->block_size == ~0) {
    return -ENOTSUP;
  }

  region->number_of_blocks = div_power2(region->region_size, region->block_size);
  dev->dev.number_of_regions = 1;
  return 0;
}

/**
 * Query device information by Device ID (ABh/9Fh) commands
 */
static int peridot_swi_flash_query_devid(peridot_swi_flash_dev *dev)
{
  static const alt_u8 cmd_did[] = {CMD_READ_DEVID, 0x00, 0x00};
  static const alt_u8 cmd_jid[] = {CMD_READ_JEDECID};
  alt_u8 device_id;
  alt_u8 buf[3];
  alt_u32 jedec_id;
  flash_region *region;

  if (peridot_swi_flash_command(
        sizeof(cmd_did), cmd_did, sizeof(device_id), &device_id, 0
      ) != sizeof(device_id)) {
    return -EIO;
  }

  if (peridot_swi_flash_command(
        sizeof(cmd_jid), cmd_jid, sizeof(buf), buf, 0
      ) != sizeof(buf)) {
    return -EIO;
  }
  jedec_id = (buf[1] << 16) | (buf[2] << 8) | (buf[3]);

  dev->page_size = 256;
  dev->four_bytes_mode = 0;

  region = &dev->dev.region_info[0];
  switch (device_id) {
    case 0x16:  // EPCS64 or compatible devices (64Mbit)
      if (jedec_id == 0x014017) {
        region->block_size = 4096;
        region->number_of_blocks = 2048;
      } else {
        region->block_size = 65536;
        region->number_of_blocks = 128;
      }
      break;
    case 0x14:  // EPCS16 or compatible devices (16Mbit)
      if (jedec_id == 0x014015) {
        region->block_size = 4096;
        region->number_of_blocks = 512;
      } else {
        region->block_size = 65536;
        region->number_of_blocks = 32;
      }
      break;
    case 0x13:  // EPCS8 or compatible devices (8Mbit)
      if (jedec_id == 0x014014) {
        region->block_size = 4096;
        region->number_of_blocks = 256;
      } else {
        region->block_size = 65536;
        region->number_of_blocks = 16;
      }
      break;
    case 0x12:  // EPCS4 or compatible devices (4Mbit)
      if (jedec_id == 0x014013) {
        region->block_size = 4096;
        region->number_of_blocks = 128;
      } else {
        region->block_size = 65536;
        region->number_of_blocks = 8;
      }
      break;
    case 0x10:  // EPCS1
      region->block_size = 32768;
      region->number_of_blocks = 4;
      break;
    default:
      return -ENOTSUP;
  }

  dev->erase_inst = (region->block_size == 4096) ? 0x20 : 0xd8;
  region->offset = 0;
  region->region_size = region->number_of_blocks * region->block_size;
  dev->dev.number_of_regions = 1;
  return 0;
}

/**
 * Query SPI flash information
 */
static int peridot_swi_flash_query(peridot_swi_flash_dev *dev)
{
  if (peridot_swi_flash_query_sfdp(dev) == 0) {
    return 0;
  }

  if (peridot_swi_flash_query_devid(dev) == 0) {
    return 0;
  }

  return -ENODEV;
}

/**
 * Set address field according to four_bytes_mode
 */
static int peridot_swi_flash_set_addr(peridot_swi_flash_dev *flash, alt_u8 *buffer, int offset)
{
  if (flash->four_bytes_mode) {
    buffer[0] = (offset >> 24) & 0xff;
    buffer[1] = (offset >> 16) & 0xff;
    buffer[2] = (offset >>  8) & 0xff;
    buffer[3] = (offset >>  0) & 0xff;
    return 4;
  } else {
    buffer[0] = (offset >> 16) & 0xff;
    buffer[1] = (offset >>  8) & 0xff;
    buffer[2] = (offset >>  0) & 0xff;
    return 3;
  }
}

/**
 * Compare data
 */
static int peridot_swi_flash_compare(alt_flash_dev *flash_info, int data_offset, const void *data, int length)
{
  peridot_swi_flash_dev *flash = (peridot_swi_flash_dev *)flash_info;
  flash_region *region = &flash_info->region_info[0];
  alt_u8 cmd[5] = {CMD_READ_BYTES};
  alt_u8 buffer[256];
  int chunk_len;
  int result;

  if ((data_offset >= region->region_size) ||
      ((data_offset + length) > region->region_size)) {
    return -EFAULT;
  }

  while (length > 0) {
    chunk_len = sizeof(buffer) > length ? sizeof(buffer) : length;
    result = peridot_swi_flash_command(
        peridot_swi_flash_set_addr(flash, cmd + 1, data_offset) + 1,
        cmd, chunk_len, buffer, 0);
    if (result < 0) {
      return result;
    }

    result = memcmp(buffer, data, chunk_len);
    if (result < 0) {
      return -1;
    } else if (result > 0) {
      return 1;
    }

    data_offset += chunk_len;
    length -= chunk_len;
    data = (const alt_u8 *)data + chunk_len;
  }

  return 0;
}

/**
 * Read bytes from flash
 */
static int peridot_swi_flash_read(alt_flash_dev *flash_info, int offset, void *dest_addr, int length)
{
  peridot_swi_flash_dev *flash = (peridot_swi_flash_dev *)flash_info;
  flash_region *region = &flash_info->region_info[0];
  alt_u8 cmd[5] = {CMD_READ_BYTES};

  if ((offset >= region->region_size) || ((offset + length) > region->region_size)) {
    return -EFAULT;
  }

  return peridot_swi_flash_command(
      peridot_swi_flash_set_addr(flash, cmd + 1, offset) + 1,
      cmd, length, dest_addr, 0);
}

/**
 * Get flash information
 */
static int peridot_swi_flash_get_info(alt_flash_fd *fd, flash_region **info, int *number_of_regions)
{
  alt_flash_dev *flash_info = (alt_flash_dev *)fd;

  if (number_of_regions) {
    *number_of_regions = flash_info->number_of_regions;
  }

  if (info) {
    *info = &flash_info->region_info[0];
  }

  return 0;
}

/**
 * Wait busy state
 */
static int peridot_swi_flash_wait_busy(void)
{
  const alt_u8 cmd = CMD_READ_STATUS;
  alt_u8 status;
  int result;

  for (;;) {
    result = peridot_swi_flash_command(1, &cmd, 1, &status, 0);
    if (result < 0) {
      return result;
    }

    if ((status & 0x01) == 0) {
      break;
    }
  }

  return 0;
}

/**
 * Erase block
 */
static int peridot_swi_flash_erase_block(alt_flash_dev *flash_info, int block_offset)
{
  peridot_swi_flash_dev *flash = (peridot_swi_flash_dev *)flash_info;
  flash_region *region = &flash_info->region_info[0];
  alt_u8 cmd[5];
  int result;

  if (block_offset >= flash_info->length) {
    return -EFAULT;
  }

  if ((block_offset & (region->block_size - 1)) != 0) {
    return -EINVAL;
  }

  cmd[0] = CMD_WRITE_ENABLE;
  result = peridot_swi_flash_command(1, cmd, 0, NULL, 0);
  if (result < 0) {
    return result;
  }

  cmd[0] = flash->erase_inst;
  result = peridot_swi_flash_command(
      peridot_swi_flash_set_addr(flash, cmd + 1, block_offset) + 1,
      cmd, 0, NULL, 0);
  if (result < 0) {
    return result;
  }

  return peridot_swi_flash_wait_busy();
}

/**
 * Write block
 */
static int peridot_swi_flash_write_block(alt_flash_dev *flash_info, int block_offset, int data_offset, const void *data, int length)
{
  peridot_swi_flash_dev *flash = (peridot_swi_flash_dev *)flash_info;
  flash_region *region = &flash_info->region_info[0];
  alt_u8 cmd[5];
  int result;

  if ((data_offset >= flash_info->length) ||
      ((data_offset + length) > flash_info->length)) {
    return -EFAULT;
  }

  block_offset = div_power2(data_offset, region->block_size);

  while (length > 0) {
    int page_offset = data_offset & (flash->page_size - 1);
    int page_length = flash->page_size - page_offset;

    cmd[0] = CMD_WRITE_ENABLE;
    result = peridot_swi_flash_command(1, cmd, 0, NULL, 0);
    if (result < 0) {
      return result;
    }

    cmd[0] = CMD_PAGE_PROGRAM;
    result = peridot_swi_flash_command(
        peridot_swi_flash_set_addr(flash, cmd + 1, data_offset) + 1,
        cmd, 0, NULL, PERIDOT_SWI_FLASH_COMMAND_MERGE);
    if (result < 0) {
      return result;
    }

    result = peridot_swi_flash_command(page_length, data, 0, NULL, 0);
    if (result < 0) {
      return result;
    }

    result = peridot_swi_flash_wait_busy();
    if (result < 0) {
      return result;
    }

    data_offset += page_length;
    length -= page_length;
    data = (const alt_u8 *)data + page_length;
  }

  return 0;
}

/**
 * Write bytes (erase and program) to flash
 */
static int peridot_swi_flash_write(alt_flash_dev *flash_info, int offset, const void *src_addr, int length)
{
  flash_region *region = &flash_info->region_info[0];
  int result;

  if ((offset >= region->region_size) ||
      ((offset + length) > region->region_size)) {
    return -EFAULT;
  }

  while (length > 0) {
    int block_offset = offset & ~(region->block_size - 1);
    int block_length = region->block_size - block_offset;

    if (length < block_length) {
      block_length = length;
    }

    if (peridot_swi_flash_compare(flash_info, offset, src_addr, block_length) != 0) {
      result = (*flash_info->erase_block)(flash_info, block_offset);
      if (result < 0) {
        return result;
      }

      result = (*flash_info->write_block)(flash_info, block_offset, offset, src_addr, block_length);
      if (result < 0) {
        return result;
      }
    }

    offset += block_length;
    src_addr = (const alt_u8 *)src_addr + block_length;
    length -= block_length;
  }

  return 0;
}

/**
 * Initialize alt_flash_dev for SPI flash via SWI's EPCS interface
 */
void peridot_swi_flash_init(peridot_swi_flash_dev *dev, const char *name)
{
  if (peridot_swi_flash_query(dev) != 0) {
    // No available SPI flash
    return;
  }

  dev->dev.name  = name;
  dev->dev.write = peridot_swi_flash_write;
  dev->dev.read  = peridot_swi_flash_read;
  dev->dev.get_info = peridot_swi_flash_get_info;
  dev->dev.erase_block = peridot_swi_flash_erase_block;
  dev->dev.write_block = peridot_swi_flash_write_block;

  alt_flash_device_register(&dev->dev);
}

