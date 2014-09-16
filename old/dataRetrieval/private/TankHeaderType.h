#ifndef TANK_HEADER_TYPE_H
#define TANK_HEADER_TYPE_H

#include <vector>
#include "MexDataTypes.h"
#include "TDTDataTypes.h"
#include "ChannelEntryType.h"

class TankDataType;

// TankHeaderType represents the entire TSQ file, and the channels of interest
// a single instance represents a single data 'stripe' in the TEV file
class TankHeaderType{
    
public:
    TankHeaderType();
    
    ~TankHeaderType();
    
    // Format of the data to be read
    TDTDataTypes::DataFormatType mFormat;
    
    // list of channel #
    std::vector<MexSupport::MexUInt32> mChannels;
    
    // whether or not each channel was found
    std::vector<bool> mFound;
    
    // total size of a given channel, in # words
    std::vector<MexSupport::MexUInt32> mTotalSize;
    
    // header data for each channel
    std::vector<ChannelEntryType> mChannelEntries;
    
    TankDataType *mpTankData;
    
protected:
    TankHeaderType(const TankHeaderType &);
    TankHeaderType& operator=(const TankHeaderType &);
};
#endif
