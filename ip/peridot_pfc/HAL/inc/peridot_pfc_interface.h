#ifndef __PERIDOT_PFC_INTERFACE_H__
#define __PERIDOT_PFC_INTERFACE_H__

#include "alt_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct peridot_pfc_map_io_s
{
  alt_8 out_funcs[32];
  alt_8 in_bank;
  alt_8 in_func;
  alt_8 in_pins[32];
}
peridot_pfc_map_io;

typedef struct peridot_pfc_map_in_s
{
  alt_8 in_bank;
  alt_8 in_func;
  alt_8 in_pins[32];
}
peridot_pfc_map_in;

typedef struct peridot_pfc_map_out_s
{
  alt_8 out_funcs[32];
}
peridot_pfc_map_out;

typedef struct peridot_pfc_map_out_ch_s
{
  alt_8 out_funcs[32];
  alt_8 out_channels[32];
}
peridot_pfc_map_out_ch;

#define PERIDOT_PFC_OUTPUT_PINX_MSK         (0xf)
#define PERIDOT_PFC_OUTPUT_PINX_WIDTH       (4)
#define PERIDOT_PFC_OUTPUT_PINX_HIZ         (0x0)
#define PERIDOT_PFC_OUTPUT_PINX_DOUT        (0x1)
#define PERIDOT_PFC_OUTPUT_PINX_AUX0        (0x4)
#define PERIDOT_PFC_OUTPUT_PINX_AUX1        (0x5)
#define PERIDOT_PFC_OUTPUT_PINX_AUX2        (0x6)
#define PERIDOT_PFC_OUTPUT_PINX_AUX3        (0x7)
#define PERIDOT_PFC_OUTPUT_PINX_FUNC0       (0x8)
#define PERIDOT_PFC_OUTPUT_PINX_FUNC1       (0x9)
#define PERIDOT_PFC_OUTPUT_PINX_FUNC2       (0xa)
#define PERIDOT_PFC_OUTPUT_PINX_FUNC3       (0xb)
#define PERIDOT_PFC_OUTPUT_PINX_FUNC4       (0xc)
#define PERIDOT_PFC_OUTPUT_PINX_FUNC5       (0xd)
#define PERIDOT_PFC_OUTPUT_PINX_FUNC6       (0xe)
#define PERIDOT_PFC_OUTPUT_PINX_FUNC7       (0xf)

#define PERIDOT_PFC_INPUT_FUNCX_MSK         (0xf)
#define PERIDOT_PFC_INPUT_FUNCX_WIDTH       (4)
#define PERIDOT_PFC_INPUT_FUNCX_LOW         (0x0)
#define PERIDOT_PFC_INPUT_FUNCX_HIGH        (0x1)
#define PERIDOT_PFC_INPUT_FUNCX_AUX0        (0x2)
#define PERIDOT_PFC_INPUT_FUNCX_AUX1        (0x3)
#define PERIDOT_PFC_INPUT_FUNCX_AUX2        (0x4)
#define PERIDOT_PFC_INPUT_FUNCX_AUX3        (0x5)
#define PERIDOT_PFC_INPUT_FUNCX_AUX4        (0x6)
#define PERIDOT_PFC_INPUT_FUNCX_AUX5        (0x7)
#define PERIDOT_PFC_INPUT_FUNCX_PIN0        (0x8)
#define PERIDOT_PFC_INPUT_FUNCX_PIN1        (0x9)
#define PERIDOT_PFC_INPUT_FUNCX_PIN2        (0xa)
#define PERIDOT_PFC_INPUT_FUNCX_PIN3        (0xb)
#define PERIDOT_PFC_INPUT_FUNCX_PIN4        (0xc)
#define PERIDOT_PFC_INPUT_FUNCX_PIN5        (0xd)
#define PERIDOT_PFC_INPUT_FUNCX_PIN6        (0xe)
#define PERIDOT_PFC_INPUT_FUNCX_PIN7        (0xf)

extern void peridot_pfc_interface_init(alt_u32 base);

extern alt_u32 peridot_pfc_interface_direct_input(alt_u32 pin);
extern void peridot_pfc_interface_direct_output(alt_u32 pin, alt_u32 value);
extern void peridot_pfc_interface_select_output(alt_u32 pin, alt_u32 func);
extern alt_u32 peridot_pfc_interface_get_output_selection(alt_u32 pin);
extern void peridot_pfc_interface_select_input(alt_u32 bank, alt_u32 func, alt_u32 pin);

extern alt_u32 peridot_pfc_interface_direct_input_bank(alt_u32 bank);
extern void peridot_pfc_interface_direct_output_bank(alt_u32 bank, alt_u32 set, alt_u32 clear, alt_u32 toggle);
extern void peridot_pfc_interface_select_output_bank(alt_u32 bank, alt_u32 bits, alt_u32 func);

#define PERIDOT_PFC_INTERFACE_INSTANCE(name, dev) extern int alt_no_storage

#define PERIDOT_PFC_INTERFACE_INIT(name, dev) peridot_pfc_interface_init(name##_BASE)

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __PERIDOT_PFC_INTERFACE_H__ */
