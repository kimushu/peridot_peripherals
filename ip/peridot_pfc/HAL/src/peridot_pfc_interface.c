#include "alt_types.h"
#include "peridot_pfc_interface.h"
#include "peridot_pfc_interface_regs.h"

static alt_u32 pfc_base;

void peridot_pfc_interface_init(alt_u32 base)
{
	pfc_base = base;
}

alt_u32 peridot_pfc_interface_direct_input(alt_u32 pin)
{
	return (IORD_PERIDOT_PFC_DIRIN(pfc_base, (pin >> PERIDOT_PFC_BANK_SHIFT)) >>
			(PERIDOT_PFC_DIRIN_DIN_OFST + (pin & PERIDOT_PFC_BANK_MASK))) & 1u;
}

void peridot_pfc_interface_direct_output(alt_u32 pin, alt_u32 value)
{
	IOWR_PERIDOT_PFC_DIROUT(pfc_base, (pin >> PERIDOT_PFC_BANK_SHIFT),
			((~1u << (PERIDOT_PFC_DIROUT_MASK_OFST + (pin & PERIDOT_PFC_BANK_MASK))) &
				PERIDOT_PFC_DIROUT_MASK_MSK) |
			(value ? (1u << (PERIDOT_PFC_DIROUT_DOUT_OFST + (pin & PERIDOT_PFC_BANK_MASK))) : 0));
}

void peridot_pfc_interface_select_output(alt_u32 pin, alt_u32 func)
{
	alt_u32 bank = (pin >> PERIDOT_PFC_BANK_SHIFT);
	pin &= PERIDOT_PFC_BANK_MASK;
	IOWR_PERIDOT_PFC_OUTPUT(pfc_base, bank,
			(IORD_PERIDOT_PFC_OUTPUT(pfc_base, bank) &
			 ~(PERIDOT_PFC_OUTPUT_PIN0_MSK <<
			   (PERIDOT_PFC_OUTPUT_PIN0_OFST +
				PERIDOT_PFC_OUTPUT_PINX_WIDTH * pin))) |
			((func & PERIDOT_PFC_OUTPUT_PINX_MSK) <<
			 (PERIDOT_PFC_OUTPUT_PIN0_OFST +
			  PERIDOT_PFC_OUTPUT_PINX_WIDTH * pin)));
}

alt_u32 peridot_pfc_interface_get_output_selection(alt_u32 pin)
{
	alt_u32 bank = (pin >> PERIDOT_PFC_BANK_SHIFT);
	pin &= PERIDOT_PFC_BANK_MASK;
	return (IORD_PERIDOT_PFC_OUTPUT(pfc_base, bank) >>
			(PERIDOT_PFC_OUTPUT_PINX_WIDTH * pin)) &
				PERIDOT_PFC_OUTPUT_PINX_MSK;
}

void peridot_pfc_interface_select_input(alt_u32 bank, alt_u32 func, alt_u32 pin)
{
	bank &= (PERIDOT_PFC_BANK_COUNT - 1);
	func &= PERIDOT_PFC_BANK_MASK;
	IOWR_PERIDOT_PFC_INPUT(pfc_base, bank,
			(IORD_PERIDOT_PFC_INPUT(pfc_base, bank) &
			 ~(PERIDOT_PFC_INPUT_FUNC0_MSK <<
			   (PERIDOT_PFC_INPUT_FUNC0_OFST +
				PERIDOT_PFC_INPUT_FUNCX_WIDTH * func))) |
			((pin & PERIDOT_PFC_INPUT_FUNCX_MSK) <<
			 (PERIDOT_PFC_INPUT_FUNC0_OFST +
			  PERIDOT_PFC_INPUT_FUNCX_WIDTH * func)));
}

alt_u32 peridot_pfc_interface_direct_input_bank(alt_u32 bank)
{
	bank &= (PERIDOT_PFC_BANK_COUNT - 1);
	return (IORD_PERIDOT_PFC_DIRIN(pfc_base, bank) & PERIDOT_PFC_DIRIN_DIN_MSK) >>
			PERIDOT_PFC_DIRIN_DIN_OFST;
}

void peridot_pfc_interface_direct_output_bank(alt_u32 bank, alt_u32 set,
		alt_u32 clear, alt_u32 toggle)
{
	bank &= (PERIDOT_PFC_BANK_COUNT - 1);
	if (toggle != 0)
	{
		alt_u32 now = IORD_PERIDOT_PFC_DIROUT(pfc_base, bank) >>
				PERIDOT_PFC_DIROUT_DOUT_OFST;
		set |= (~now & toggle);
		clear |= (now & toggle);
	}

	IOWR_PERIDOT_PFC_DIROUT(pfc_base, bank,
			((~(set | clear | toggle) << PERIDOT_PFC_DIROUT_MASK_OFST) &
				PERIDOT_PFC_DIROUT_MASK_MSK) |
			((set << PERIDOT_PFC_DIROUT_DOUT_OFST) &
				PERIDOT_PFC_DIROUT_DOUT_MSK));
}

void peridot_pfc_interface_select_output_bank(alt_u32 bank, alt_u32 bits, alt_u32 func)
{
	alt_u32 mask;
	bank &= (PERIDOT_PFC_BANK_COUNT - 1);
#if PERIDOT_PFC_OUTPUT_PINX_WIDTH == 4
	/* pqrstuvw (binary) --> 000p000q000r000s000t000u000v000w (binary) */
	mask = (((bits & 0x55) * 0x00041041) & 0x01010101) |
			(((bits & 0xaa) * 0x00208208) & 0x10101010);
	IOWR_PERIDOT_PFC_OUTPUT(pfc_base, bank,
			(IORD_PERIDOT_PFC_OUTPUT(pfc_base, bank) &
				(mask ^ 0x11111111) * PERIDOT_PFC_OUTPUT_PINX_MSK) |
			(mask * (func & PERIDOT_PFC_OUTPUT_PINX_MSK)));
#else
# error "Not implemented for current PERIDOT_PFC_OUTPUT_PINX_WIDTH value"
#endif
}

