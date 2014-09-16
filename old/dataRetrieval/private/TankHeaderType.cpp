#include "TankHeaderType.h"
#include "TankDataType.h"

#include "MexSupport.h"
TankHeaderType::TankHeaderType()
: mpTankData(0x0) {
    
}
TankHeaderType::~TankHeaderType() {
    if(mpTankData != 0x0 ) {
        delete mpTankData;
    }
}

TankHeaderType::TankHeaderType(const TankHeaderType &) {
    
}

TankHeaderType& TankHeaderType::operator=(const TankHeaderType &) {
    // CAA This has got to be an error
    return *this;
}