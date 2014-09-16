#include "mex.h"
#include <cstring>
#include <vector>
#include <utility>

#include "ReadTank.h"
#include "ChannelEntryType.h"
#include "TankHeaderType.h"

// Include the implementations of specific types
#include "TankDataTypeTemplate.h"

/* 64-bit file access is platform-dependent; use Linux GLIBC as canonical */
#ifdef RNEL_IS_MAC
/* OS X supports 64bit file access by default */
#  define off64_t  off_t
#  define fopen64  fopen
#  define fseeko64 fseeko
#endif
#ifdef RNEL_IS_PC
/* I believe Windows fopen works for both big and small files */
#  define fopen64  fopen
#  define fseeko64 _fseeki64
#endif

using namespace std;
using namespace TDTDataTypes;
using namespace MexSupport;

struct tsqEventHeader {
    MexUInt32 size;
    MexUInt32 type; /* event type: snip, pdec, epoc etc */
    MexUInt32 code; /* event name: must be 4 chars, cast as a long */
    MexUInt16 channel; /* data acquisition channel */
    MexUInt16 sortcode; /* sort code for snip data */
    MexDouble timestamp; /* time offset when even occurred */
    //     union {
    MexUInt64 ev_offset; /* data offset in the TEV file */
    //         MexDouble strobe; /* raw data value */
    //     };
    MexUInt32 format; /* data format of event: byte, short, float
     * (usually), double */
    MexFloat frequency; /* sampling frequency */
};


int read_tsq_file(const std::string &filename,
        const std::string &event,
        TankHeaderType &rHeader ) {
    int nChan = rHeader.mChannels.size();
    
    // translate the string into a word for easy comparison
    MexUInt32 the_key;
    bool success = translate_string_to_word(event.c_str(), the_key);
    
    if( !success) {
        return -1;
    }
    
    FILE*  fid      = fopen(filename.c_str(), "rb");
    if ( fid == NULL) {
        mexPrintf("Failed to open file: %s.\n", filename.c_str());
        return -1;
    }
    
    // The number of headers read at a time, increased buffering will speed things up
    int n_headers      = 200000;
    // space for raw data
    // some entries need to be later joined/split depending on entry size
    tsqEventHeader* buffer    = (tsqEventHeader*)mxMalloc(n_headers*sizeof(tsqEventHeader));
    if( buffer == 0x0) {
        mexPrintf("Out-of-Memory!!\n");
        return -1;
    }
    
    // init memory
    MexUInt32 the_size  = 0;
    DataFormatType the_format  = DFORM_FLOAT;

    bool b_format_set = false;
    while( !feof(fid)) {
        int N = fread(buffer, sizeof(tsqEventHeader), n_headers, fid);
        for( int ii = 0; ii < N; ii++) {
            tsqEventHeader& this_header = buffer[ii]; 
            if( the_key == this_header.code) {
                bool match( false );
                int iiChan  = 0;
                for( ; iiChan < nChan; iiChan++) {
                    if( this_header.channel == rHeader.mChannels[iiChan]) {
                        match = true;
                        break;
                    }
                }
                if( match ) {
                    if( !rHeader.mFound[iiChan]) {
                        rHeader.mFound[iiChan] = true;
                    }
                    
                    // For some reason there is a footer saved with each event,
                    // the length of which is included in size.  Because I don't care I
                    // subtract it off
                    the_size   = this_header.size-10;                    
                    the_format = static_cast<DataFormatType>(this_header.format);
                    
                    if(!b_format_set) {
                        rHeader.mFormat = the_format;
                        b_format_set = true;
                    }
                    else if(rHeader.mFormat != the_format) {
                        mexPrintf("The formats do not match.\n");
                        return -1;
                    }
                    rHeader.mTotalSize[iiChan] += the_size;
                    rHeader.mChannelEntries.push_back(
                            ChannelEntryType(
                            iiChan,
                            the_size, 
                            this_header.ev_offset) );
                } // if match
            } // the_key == this_key
        } // for ( int ii = 0 ...
    } // !feof
    fclose(fid);

    vector<MexUInt32>::iterator chan_iter = rHeader.mChannels.begin();
    vector<bool>::iterator found_iter     = rHeader.mFound.begin();
    vector<MexUInt32>::iterator size_iter       = rHeader.mTotalSize.begin();
    while(found_iter != rHeader.mFound.end() ) {
        if(!*found_iter) {
            chan_iter  = rHeader.mChannels.erase(chan_iter);
            found_iter = rHeader.mFound.erase(found_iter);
            size_iter  = rHeader.mTotalSize.erase(size_iter);
        }
        else {
            found_iter++;
            chan_iter++;
            size_iter++;
        }
    }
    
    // play nice with udders
    mxFree(buffer);
    return 0;
}


int read_tev_file(const std::string &filename, TankHeaderType &rHeader) {
    FILE* fid = fopen64(filename.c_str(), "rb");
    
    if ( fid == NULL) {
        mexPrintf("Failed to open file: %s.\n", filename.c_str());
        return -1;
    }
    bool failure = false;
    int nChan    = rHeader.mChannels.size();
    
    // verify that each channel is the same length
    int length = rHeader.mTotalSize[0];
    
    for(int iiChan = 1; iiChan < nChan; iiChan++) {
        if( rHeader.mFound[iiChan]
                && rHeader.mTotalSize[iiChan] != length) {
            mexPrintf("Channel[%d].size() %d != %d, cannot create a matrix.\n", \
                    iiChan, rHeader.mTotalSize[iiChan], length);
            failure = true;
        }
    }
    
    if( failure) {
        return -1;
    }
    
    try{
        switch(rHeader.mFormat) {
            case DFORM_FLOAT:
                rHeader.mpTankData = new TankDataTypeTemplate<MexFloat>(length, nChan);
                break;
            case DFORM_LONG:
                rHeader.mpTankData = new TankDataTypeTemplate<MexInt32>(length, nChan);
                break;
            case DFORM_SHORT:
                rHeader.mpTankData = new TankDataTypeTemplate<MexInt16>(length, nChan);
                break;
            case DFORM_BYTE:
                rHeader.mpTankData = new TankDataTypeTemplate<MexUInt8>(length, nChan);
                break;
            case DFORM_DOUBLE:
                rHeader.mpTankData = new TankDataTypeTemplate<MexDouble>(length, nChan);
                break;
            case DFORM_QWORD:
                rHeader.mpTankData = new TankDataTypeTemplate<MexInt64>(length, nChan);
                break;
            default:
                mexPrintf("Unknown header type %d\n",rHeader.mFormat);
                return -1;
        }
    }
    catch( ... ){
        mexPrintf("Out-of-Memory!!!\nN: %d\n", length*nChan);
        return -1;
    }
    
    // # entries total in file that we care about
    int nEntries        = rHeader.mChannelEntries.size();
    
    // current position in file, bytes
    MexUInt64 cur_pos   = 0;
    
    // amount to seek to get next entry, bytes
    MexUInt64 seek_incr = 0;
    
    const vector<ChannelEntryType> & entries      = rHeader.mChannelEntries;
    vector<ChannelEntryType>::const_iterator iter = entries.begin();
    
    // channel index
    int idx = 0;
    
    // size of current event, # floats
    int nWords = 0;
    

    for( ; iter != rHeader.mChannelEntries.end(); iter++) 
    {    
        // define the offset from current position, bytes
        seek_incr = iter->mOffset - cur_pos;
        idx       = iter->mHeaderIdx;
        nWords    = iter->mNWords;
        
        // save current offset for next seek, converting size to a number of bytes
        cur_pos  = iter->mOffset + nWords*sizeof(MexInt32);
        
        // seek from current position to next event
        if( fseeko64(fid, seek_incr, SEEK_CUR) != 0) {
            failure = true;
            break;
        }
        rHeader.mpTankData->readDataFromFile(fid, idx, nWords);   
    }
    fclose(fid);
    
    if( failure) {
        mexPrintf("Failed to read form file\n");
        // free the memory because it won't be returned to matlab
        mxFree(rHeader.mpTankData);
        rHeader.mpTankData = 0x0;
        return -1;
    }
    return 0;
}

/*
 *  bool translate_string_to_word(const char* str, unsigned int &the_key)
 *  Converts a 4 character event code and transforms it into a 32-bit int
 *  Designed to speed up the process of indexing the TDT .tsq file
 */
bool translate_string_to_word(const char* str, MexUInt32 &the_key) {
    if( strlen(str) != 4) {
        mexPrintf("Cannot convert strings length > 4");
        return false;
    }
    
    MexUInt32 one   = str[0];
    MexUInt32 two   = str[1];
    MexUInt32 three = str[2];
    MexUInt32 four  = str[3];
    
    the_key = 0;
    the_key |= one;
    the_key |= two   <<  8;
    the_key |= three << 16;
    the_key |= four  << 24;
    
    //memcpy(&the_key,reinterpret_cast<void*>(the_key),sizeof(MexUInt32));
    return true;
}
