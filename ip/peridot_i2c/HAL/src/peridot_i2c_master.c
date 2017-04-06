#include <errno.h>
#include "alt_types.h"
#include "sys/alt_irq.h"
#include "peridot_i2c_master.h"
#include "peridot_i2c_regs.h"
#include "system.h"
#ifdef __PERIDOT_PFC_INTERFACE
#include "peridot_pfc_interface.h"
#endif  /* __PERIDOT_PFC_INTERFACE */

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
static void peridot_i2c_master_irq(void *context)
#else
static void peridot_i2c_master_irq(void *context, alt_u32 id)
#endif
{
  peridot_i2c_master_state *sp = (peridot_i2c_master_state *)context;

  alt_ic_irq_disable(sp->irq_controller_id, sp->irq);
#ifdef __tinythreads__
  sem_post(&sp->done);
#else
  sp->done = 1;
#endif
}

void peridot_i2c_master_init(peridot_i2c_master_state *sp)
{
#ifdef __tinythreads__
  pthread_mutex_init(&sp->lock, NULL);
  sem_init(&sp->done, 0, 0);
#else
  sp->lock = 0;
  sp->done = 0;
#endif

  /* Enable reset */
  IOWR_PERIDOT_I2C_CONFIG(sp->base, PERIDOT_I2C_CONFIG_RST_MSK | PERIDOT_I2C_CONFIG_CLKDIV_MSK);

#ifdef __PERIDOT_PFC_INTERFACE
  /* Connect inputs to '1' */
  peridot_pfc_interface_select_input(sp->scl_pfc_map->in_bank,
                                     sp->scl_pfc_map->in_func,
                                     PERIDOT_PFC_INPUT_FUNCX_HIGH);
  peridot_pfc_interface_select_input(sp->sda_pfc_map->in_bank,
                                     sp->sda_pfc_map->in_func,
                                     PERIDOT_PFC_INPUT_FUNCX_HIGH);
#endif  /* __PERIDOT_PFC_INTERFACE */

  /* Clear reset */
  IOWR_PERIDOT_I2C_CONFIG(sp->base, PERIDOT_I2C_CONFIG_CLKDIV_MSK);

  /* Wait for ready */
  while ((IORD_PERIDOT_I2C_ACCESS(sp->base) & PERIDOT_I2C_ACCESS_RDY_MSK) == 0);

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
  alt_ic_isr_register(sp->irq_controller_id, sp->irq, peridot_i2c_master_irq, sp, NULL);
#else
  alt_irq_register(sp->irq, sp, peridot_i2c_master_irq);
#endif
}

#ifdef __PERIDOT_PFC_INTERFACE
int peridot_i2c_master_configure_pins(peridot_i2c_master_state *sp,
                                      alt_u32 scl, alt_u32 sda, int dry_run)
{
  const peridot_pfc_map_io *const scl_pfc_map = sp->scl_pfc_map;
  const peridot_pfc_map_io *const sda_pfc_map = sp->sda_pfc_map;

  if ((scl < sizeof(scl_pfc_map->out_funcs)) &&
      (scl_pfc_map->in_bank >= 0) &&
      (scl_pfc_map->in_func >= 0) &&
      (scl < sizeof(scl_pfc_map->in_pins)) &&
      (sda < sizeof(sda_pfc_map->out_funcs)) &&
      (sda_pfc_map->in_bank >= 0) &&
      (sda_pfc_map->in_func >= 0) &&
      (sda < sizeof(sda_pfc_map->in_pins)))
  {
    alt_8 scl_func = scl_pfc_map->out_funcs[scl];
    alt_8 scl_pin = scl_pfc_map->in_pins[scl];
    alt_8 sda_func = sda_pfc_map->out_funcs[sda];
    alt_8 sda_pin = sda_pfc_map->in_pins[sda];
    if ((scl_func >= 0) && (scl_pin >= 0) &&
        (sda_func >= 0) && (sda_pin >= 0))
    {
      if (!dry_run)
      {
        peridot_pfc_interface_select_output(scl, scl_func);
        peridot_pfc_interface_select_input(scl_pfc_map->in_bank, scl_pfc_map->in_func, scl_pin);
        peridot_pfc_interface_select_output(sda, sda_func);
        peridot_pfc_interface_select_input(sda_pfc_map->in_bank, sda_pfc_map->in_func, sda_pin);
      }
      return 0;
    }
  }
  return -ENOTSUP;
}
#endif  /* __PERIDOT_PFC_INTERFACE */

int peridot_i2c_master_get_clkdiv(peridot_i2c_master_state *sp, alt_u32 bitrate, alt_u32 *clkdiv)
{
  alt_32 value;
  value = (sp->freq / bitrate / 4) - 5;
  if (value < 0)
  {
    return -EINVAL;
  }

  *clkdiv = value;
  return 0;
}

static alt_u32 wait(peridot_i2c_master_state *sp)
{
  alt_u32 resp;

  alt_ic_irq_enable(sp->irq_controller_id, sp->irq);

  do
  {
#ifdef __tinythreads__
    sem_wait(&sp->done);
#else
    while (!sp->done);
#endif
  }
  while (((resp = IORD_PERIDOT_I2C_ACCESS(sp->base)) &
          PERIDOT_I2C_ACCESS_RDY_MSK) == 0);

  return resp;
}

static int transfer(peridot_i2c_master_state *sp,
                    alt_u16 slave_address, alt_u32 clkdiv,
                    alt_u32 write_length, const alt_u8 *write_data,
                    alt_u32 read_length, alt_u8 *read_data)
{
  alt_u32 base = sp->base;
  alt_u32 resp;
  alt_u8 saddr;

  if (slave_address & PERIDOT_I2C_MASTER_10BIT_ADDRESS)
  {
    return -ENOTSUP;  // TODO
  }
  else
  {
    saddr = (slave_address << 1) & 0xfe;
  }

  /* Wait for ready */
  while ((IORD_PERIDOT_I2C_ACCESS(base) & PERIDOT_I2C_ACCESS_RDY_MSK) == 0);

  /* Set CLKDIV */
  IOWR_PERIDOT_I2C_CONFIG(base,
      (clkdiv << PERIDOT_I2C_CONFIG_CLKDIV_OFST) &
        PERIDOT_I2C_CONFIG_CLKDIV_MSK);

  if (write_length > 0)
  {
    /* Start condition & slave address for writing */
    IOWR_PERIDOT_I2C_ACCESS(base,
        PERIDOT_I2C_ACCESS_IRQENA_MSK |
        PERIDOT_I2C_ACCESS_SC_MSK |
        PERIDOT_I2C_ACCESS_STA_MSK |
        (((saddr | 0x00) << PERIDOT_I2C_ACCESS_TXDATA_OFST) &
          PERIDOT_I2C_ACCESS_TXDATA_MSK)
    );

    resp = wait(sp);
    if (resp & PERIDOT_I2C_ACCESS_NACK_MSK)
    {
      /* Stop condition with dummy write */
      IOWR_PERIDOT_I2C_ACCESS(base,
          PERIDOT_I2C_ACCESS_IRQENA_MSK |
          PERIDOT_I2C_ACCESS_PC_MSK |
          PERIDOT_I2C_ACCESS_STA_MSK |
          PERIDOT_I2C_ACCESS_TXDATA_MSK
      );
      wait(sp);
      return -ENOENT;
    }

    for (; write_length > 0; --write_length)
    {
      /* Write data */
      IOWR_PERIDOT_I2C_ACCESS(base,
          PERIDOT_I2C_ACCESS_IRQENA_MSK |
          ((write_length == 1) && (read_length == 0) ?
            PERIDOT_I2C_ACCESS_PC_MSK : 0) |
          PERIDOT_I2C_ACCESS_STA_MSK |
          ((*write_data++ << PERIDOT_I2C_ACCESS_TXDATA_OFST) &
            PERIDOT_I2C_ACCESS_TXDATA_MSK)
      );

      resp = wait(sp);
      if (resp & PERIDOT_I2C_ACCESS_NACK_MSK)
      {
        if ((write_length > 1) || (read_length > 0))
        {
          /* Stop condition with dummy write */
          IOWR_PERIDOT_I2C_ACCESS(base,
              PERIDOT_I2C_ACCESS_IRQENA_MSK |
              PERIDOT_I2C_ACCESS_PC_MSK |
              PERIDOT_I2C_ACCESS_STA_MSK |
              PERIDOT_I2C_ACCESS_TXDATA_MSK
          );
          wait(sp);
        }
        return -ECANCELED;
      }
    }
  }

  if (read_length > 0)
  {
    /* (Re-)start condition & slave address for reading */
    IOWR_PERIDOT_I2C_ACCESS(base,
        PERIDOT_I2C_ACCESS_IRQENA_MSK |
        PERIDOT_I2C_ACCESS_SC_MSK |
        PERIDOT_I2C_ACCESS_STA_MSK |
        (((saddr | 0x01) << PERIDOT_I2C_ACCESS_TXDATA_OFST) &
          PERIDOT_I2C_ACCESS_TXDATA_MSK)
    );

    resp = wait(sp);
    if (resp & PERIDOT_I2C_ACCESS_NACK_MSK)
    {
      /* Stop condition with dummy read */
      IOWR_PERIDOT_I2C_ACCESS(base,
          PERIDOT_I2C_ACCESS_IRQENA_MSK |
          PERIDOT_I2C_ACCESS_PC_MSK |
          PERIDOT_I2C_ACCESS_NACK_MSK |
          PERIDOT_I2C_ACCESS_DIR_MSK |
          PERIDOT_I2C_ACCESS_STA_MSK
      );
      wait(sp);
      return -ENOENT;
    }

    for (; read_length > 0; --read_length)
    {
      /* Read data */
      IOWR_PERIDOT_I2C_ACCESS(base,
          PERIDOT_I2C_ACCESS_IRQENA_MSK |
          ((read_length == 1) ?
            PERIDOT_I2C_ACCESS_PC_MSK |
            PERIDOT_I2C_ACCESS_NACK_MSK : 0) |
          PERIDOT_I2C_ACCESS_DIR_MSK |
          PERIDOT_I2C_ACCESS_STA_MSK
      );

      resp = wait(sp);
      *read_data++ = (resp & PERIDOT_I2C_ACCESS_RXDATA_MSK) >>
                      PERIDOT_I2C_ACCESS_RXDATA_OFST;
    }
  }

  return 0;
}

int peridot_i2c_master_transfer(peridot_i2c_master_state *sp,
                                alt_u16 slave_address, alt_u32 clkdiv,
                                alt_u32 write_length, const alt_u8 *write_data,
                                alt_u32 read_length, alt_u8 *read_data)
{
  int result;

#ifdef __tinythreads__
  pthread_mutex_lock(&sp->lock);
#else
  {
    alt_u8 locked;
    alt_irq_context context = alt_irq_disable_all();
    locked = sp->lock;
    sp->lock = 1;
    alt_irq_enable_all(context);
    if (locked)
    {
      return -EAGAIN;
    }
  }
#endif

  result = transfer(sp, slave_address, clkdiv,
                    write_length, write_data, read_length, read_data);

#ifdef __tinythreads__
  pthread_mutex_unlock(&sp->lock);
#else
  sp->lock = 0;
#endif

  return result;
}

