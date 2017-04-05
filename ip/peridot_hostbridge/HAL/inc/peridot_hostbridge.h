#ifndef __PERIDOT_HOSTBRIDGE_H__
#define __PERIDOT_HOSTBRIDGE_H__

#include "peridot_swi.h"

#define PERIDOT_HOSTBRIDGE_INSTANCE(name, state) \
  PERIDOT_SWI_INSTANCE(name, state)

#define PERIDOT_HOSTBRIDGE_INIT(name, state) \
  PERIDOT_SWI_INIT(name, state)

#endif /* __PERIDOT_HOSTBRIDGE_H__ */
