#ifndef CHANNEL_ENTRY_TYPE_H
#define CHANNEL_ENTRY_TYPE_H
    // ChannelEntryType represents a single channel entry in the TSQ file
    // a single instance represents a single data 'stripe' in the TEV file
#include "MexDataTypes.h"
struct ChannelEntryType{
    ChannelEntryType()
    : mHeaderIdx(0), mNWords(0), mOffset(0) {
    }
    
    ChannelEntryType(int idx, unsigned int size, MexSupport::MexInt64 offset)
    : mHeaderIdx(idx), mNWords(size), mOffset(offset) {
    }
    // index into TankHeadType channels for this entry
    int mHeaderIdx;
    
    // size of this entry, in # words
    unsigned int mNWords;
    
    // offset into TEV file, bytes
    MexSupport::MexInt64 mOffset;
};
#endif
