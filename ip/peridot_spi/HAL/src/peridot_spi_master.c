#include <errno.h>
#include "alt_types.h"
#include "sys/alt_irq.h"
#include "peridot_spi_master.h"
#include "peridot_spi_regs.h"
#include "system.h"
#ifdef __PERIDOT_PFC_INTERFACE
# include "peridot_pfc_interface.h"
#endif  /* __PERIDOT_PFC_INTERFACE */

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
static void peridot_spi_master_irq(void *context)
#else
static void peridot_spi_master_irq(void *context, alt_u32 id)
#endif
{
  peridot_spi_master_state *sp = (peridot_spi_master_state *)context;

  alt_ic_irq_disable(sp->irq_controller_id, sp->irq);
#ifdef __tinythreads__
  sem_post(&sp->done);
#else
  sp->done = 1;
#endif
}

void peridot_spi_master_init(peridot_spi_master_state *sp
                             PERIDOT_SPI_FLASH_INIT_ARGS)
{
#ifdef __tinythreads__
  pthread_mutex_init(&sp->lock, NULL);
  sem_init(&sp->done, 0, 0);
#else
  sp->lock = 0;
  sp->done = 0;
#endif
  sp->slave_locked = -1;

#ifdef ALT_ENHANCED_INTERRUPT_API_PRESENT
  alt_ic_isr_register(sp->irq_controller_id, sp->irq, peridot_spi_master_irq, sp, NULL);
#else
  alt_irq_register(sp->irq, sp, peridot_spi_master_irq);
#endif

  PERIDOT_SPI_FLASH_INIT_CALL();
}

#ifdef __PERIDOT_PFC_INTERFACE
int peridot_spi_master_configure_pins(const peridot_spi_master_pfc_map *map,
                                      alt_u32 sclk, alt_32 mosi, alt_32 miso, int dry_run)
{
  const peridot_pfc_map_out *const sclk_pfc_map = map->sclk_pfc_map;
  const peridot_pfc_map_out *const mosi_pfc_map = map->mosi_pfc_map;
  const peridot_pfc_map_in  *const miso_pfc_map = map->miso_pfc_map;
  map->sp->ss_n_pfc_map = map->ss_n_pfc_map;

  if ((sclk < sizeof(sclk_pfc_map->out_funcs)) &&
      ((mosi < 0) || (mosi < sizeof(mosi_pfc_map->out_funcs))) &&
      ((miso < 0) || (
        (miso_pfc_map->in_bank >= 0) &&
        (miso_pfc_map->in_func >= 0) &&
        (miso < sizeof(miso_pfc_map->in_pins)))))
  {
    alt_8 sclk_func = sclk_pfc_map->out_funcs[sclk];
    alt_8 mosi_func = (mosi < 0) ? 0 : mosi_pfc_map->out_funcs[mosi];
    alt_8 miso_pin = (miso < 0) ? 0 : miso_pfc_map->in_pins[miso];
    if ((sclk_func >= 0) && ((mosi < 0) || (mosi_func >= 0)) &&
        ((miso < 0) || (miso_pin >= 0)))
    {
      if (!dry_run)
      {
        if (map->sp->slave_locked >= 0)
        {
          return -EAGAIN;
        }
        peridot_pfc_interface_select_output(sclk, sclk_func);
        if (mosi >= 0)
        {
          peridot_pfc_interface_select_output(mosi, mosi_func);
        }
        peridot_pfc_interface_select_input(miso_pfc_map->in_bank, miso_pfc_map->in_func,
                                           (miso < 0) ?
                                           PERIDOT_PFC_INPUT_FUNCX_HIGH : miso_pin);
      }
      return 0;
    }
  }
  return -ENOTSUP;
}
#endif  /* __PERIDOT_PFC_INTERFACE */

int peridot_spi_master_get_clkdiv(peridot_spi_master_state *sp, alt_u32 bitrate, alt_u32 *clkdiv)
{
  alt_32 value;
  value = (sp->freq / bitrate / 2) - 1;
  if (value < 0)
  {
    return -EINVAL;
  }

  *clkdiv = value;
  return 0;
}

static alt_u32 wait(peridot_spi_master_state *sp)
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
  while (((resp = IORD_PERIDOT_SPI_ACCESS(sp->base)) &
          PERIDOT_SPI_ACCESS_RDY_MSK) == 0);

  return resp;
}

static int transfer(peridot_spi_master_state *sp,
                    alt_8 slave, alt_u32 clkdiv,
                    alt_u32 write_length, const alt_u8 *write_data,
                    alt_u32 read_skip, alt_u32 read_length, alt_u8 *read_data,
                    alt_u32 flags)
{
  alt_u32 base = sp->base;
  alt_u32 resp;

  if ((sp->slave_locked >= 0) && (sp->slave_locked != slave))
  {
    /*
     * The transaction between another slave is in progress
     */
    return -EAGAIN;
  }

#ifdef __PERIDOT_PFC_INTERFACE
  if ((slave >= 0) && (sp->ss_n_pfc_map))
  {
    /* Connect ss_n output to the slave */
    peridot_pfc_interface_select_output(slave, sp->ss_n_pfc_map->out_funcs[slave]);
  }
#endif  /* __PERIDOT_PFC_INTERFACE */

  /* Wait for ready */
  while ((IORD_PERIDOT_SPI_ACCESS(base) & PERIDOT_SPI_ACCESS_RDY_MSK) == 0);

  /* Set configurations */
  IOWR_PERIDOT_SPI_CONFIG(base,
      ((clkdiv << PERIDOT_SPI_CONFIG_CLKDIV_OFST) &
        PERIDOT_SPI_CONFIG_CLKDIV_MSK) |
      (((flags & PERIDOT_SPI_MASTER_MODE_MSK) >>
          PERIDOT_SPI_MASTER_MODE_OFST) << PERIDOT_SPI_CONFIG_MODE_OFST) |
      ((flags & PERIDOT_SPI_MASTER_LSBFIRST) ?
        PERIDOT_SPI_CONFIG_RVS_MSK : 0));

  /* Assert slave select */
  IOWR_PERIDOT_SPI_ACCESS(base, PERIDOT_SPI_ACCESS_SS_MSK);

  for (; write_length > 0; --write_length)
  {
    /* Write data */
    IOWR_PERIDOT_SPI_ACCESS(base,
        PERIDOT_SPI_ACCESS_IRQENA_MSK |
        PERIDOT_SPI_ACCESS_STA_MSK |
        PERIDOT_SPI_ACCESS_SS_MSK |
        ((*write_data++ << PERIDOT_SPI_ACCESS_TXDATA_OFST) &
          PERIDOT_SPI_ACCESS_TXDATA_MSK));
    resp = wait(sp);

    if (read_skip > 0)
    {
      --read_skip;
    }
    else if (read_length > 0)
    {
      /* Read data */
      *read_data++ = (resp & PERIDOT_SPI_ACCESS_RXDATA_MSK) >>
                      PERIDOT_SPI_ACCESS_RXDATA_OFST;
      --read_length;
    }
  }

  for (; read_skip > 0; --read_skip)
  {
    /* Write filler */
    IOWR_PERIDOT_SPI_ACCESS(base,
        PERIDOT_SPI_ACCESS_IRQENA_MSK |
        PERIDOT_SPI_ACCESS_STA_MSK |
        PERIDOT_SPI_ACCESS_SS_MSK |
        ((((flags & PERIDOT_SPI_MASTER_FILLER_MSK) >>
              PERIDOT_SPI_MASTER_FILLER_OFST) <<
            PERIDOT_SPI_ACCESS_TXDATA_OFST) &
          PERIDOT_SPI_ACCESS_TXDATA_MSK));
    wait(sp);
  }

  for (; read_length > 0; --read_length)
  {
    /* Write filler */
    IOWR_PERIDOT_SPI_ACCESS(base,
        PERIDOT_SPI_ACCESS_IRQENA_MSK |
        PERIDOT_SPI_ACCESS_STA_MSK |
        PERIDOT_SPI_ACCESS_SS_MSK |
        ((((flags & PERIDOT_SPI_MASTER_FILLER_MSK) >>
              PERIDOT_SPI_MASTER_FILLER_OFST) <<
            PERIDOT_SPI_ACCESS_TXDATA_OFST) &
          PERIDOT_SPI_ACCESS_TXDATA_MSK));
    resp = wait(sp);

    /* Read data */
    *read_data++ = (resp & PERIDOT_SPI_ACCESS_RXDATA_MSK) >>
                    PERIDOT_SPI_ACCESS_RXDATA_OFST;
  }

  if (flags & PERIDOT_SPI_MASTER_MERGE)
  {
    /* Keep slave select asserted */
    sp->slave_locked = slave;
  }
  else
  {
    /* Negate slave select */
    IOWR_PERIDOT_SPI_ACCESS(base, 0);
#ifdef __PERIDOT_PFC_INTERFACE
    peridot_pfc_interface_direct_output(slave, 1);
    peridot_pfc_interface_select_output(slave, PERIDOT_PFC_OUTPUT_PINX_DOUT);
#endif  /* __PERIDOT_PFC_INTERFACE */
    sp->slave_locked = -1;
  }

  return 0;
}

int peridot_spi_master_transfer(peridot_spi_master_state *sp,
                                alt_8 slave, alt_u32 clkdiv,
                                alt_u32 write_length, const alt_u8 *write_data,
                                alt_u32 read_skip, alt_u32 read_length, alt_u8 *read_data,
                                alt_u32 flags)
{
  int result;

#ifdef __PERIDOT_PFC_INTERFACE
  if (sp->ss_n_pfc_map)
  {
    if ((slave >= sizeof(sp->ss_n_pfc_map->out_funcs)) ||
        ((slave >= 0) && (sp->ss_n_pfc_map->out_funcs[slave] < 0)))
    {
      return -EINVAL;
    }
  }
#endif  /* __PERIDOT_PFC_INTERFACE */

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

  result = transfer(sp, slave, clkdiv,
                    write_length, write_data,
                    read_skip, read_length, read_data, flags);

#ifdef __tinythreads__
  pthread_mutex_unlock(&sp->lock);
#else
  sp->lock = 0;
#endif

  return result;
}

