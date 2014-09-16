#ifndef TANK_DATA_TYPE_TEMPLATE_H
#define TANK_DATA_TYPE_TEMPLATE_H
#include "matrix.h"
#include <cstdio>
#include <vector>
#include <stdexcept>
#include "TankDataType.h"
#include "MexSupport.h"

// disable throw decl. warning
#pragma warning(disable: 4290)

template<class T>
        class TankDataTypeTemplate : public TankDataType{
            // TankDataType represents the entire TSQ file, and the channels of interest
            // a single instance represents a single data 'stripe' in the TEV file
            
        public:
            // CTOR, allocates memory buffer for storing events
            // @param nWordPerRow - number of words in a single row, converted to # rows internally
            // @param nCol - number of columns
            // @exception throws on out-of-memory
            TankDataTypeTemplate(unsigned int nWordPerRow, unsigned int nCol)
            throw (std::runtime_error);

            // If instance still owns its mpRawDAta memory it will be freed
            virtual ~TankDataTypeTemplate();
            
            // @brief Reads data from TEV File. Abstact interface
            // @param fid - TEV file pointer
            // @param colIdx - column index within this matrix, as decided by channel number
            // @param nWords - # of words to read
            inline void readDataFromFile(FILE * fid, unsigned int colIdx, unsigned int nWords);
            
            // @brief retrieve the number of array elements are in a word
            float getNElementsPerWord() const;
            
            // @brief Assign internal data to an mxArray for output.
            // @param rpMxArray array to contain memory, any existing data will be cleared
            void assignToMxArray(mxArray*& rpMxArray);

        private:
                  
            bool allocateMemory(unsigned int nWordPerRow, unsigned int nCol);
            
            // Copy CTOR, locked
            TankDataTypeTemplate(const TankDataTypeTemplate& );
            
            // Assignment operator, locked
            TankDataTypeTemplate& operator=(const TankDataTypeTemplate& );
            
            // Raw data for all channels, each column represents a row
            T* mpRawData;
            
            // number of elements per word
            float mNElementsPerWord;
            
            // offset of each ptr, indexed by channel
            std::vector<MexSupport::MexUInt32> mPtrOffset;
            
            // header data for each channel
            std::vector<ChannelEntryType> mChannelEntries;
        };
        
template< class T >
TankDataTypeTemplate< T >::TankDataTypeTemplate(unsigned int nWordPerRow, unsigned int nCol) throw (std::runtime_error)
: TankDataType(), mpRawData(0x0),
        mNElementsPerWord( sizeof(MexSupport::MexInt32)/(float)sizeof(T))   {
    if(!allocateMemory(nWordPerRow, nCol)) {
        throw(std::runtime_error("TankDataTypeTemplate::allocateMemory Failed!"));
    }
}

template< class T >
        TankDataTypeTemplate< T >::~TankDataTypeTemplate() {
    if( mpRawData != 0x0) {
        delete mpRawData;
    }
}

template< class T >
        float TankDataTypeTemplate< T >::getNElementsPerWord() const{
    return mNElementsPerWord;
}

template< class T >
        bool TankDataTypeTemplate< T >::allocateMemory(unsigned int nWordPerRow, unsigned int nCol){
    mpRawData = (T*)mxMalloc(nWordPerRow*nCol*sizeof(MexSupport::MexInt32));

    if( mpRawData == 0x0 )
        return false;

    mPtrOffset.resize(nCol, 0);
    mNCol     = nCol;
    mNRow     = (unsigned int)(nWordPerRow*mNElementsPerWord);
    int numel = 0;
    // get the total number of elements
    for(unsigned int iiCol = 0; iiCol < nCol; iiCol++) {
        if( iiCol > 0) {
            // each channel starts immediately after the previous one in memory.
            // By setting the dimensions of the mxArray correctly this will
            // result in a length x nChannels matrix
            mPtrOffset[iiCol] = numel;
        }
        numel += mNRow;
    }
    return true;
}

template< class T >
        void TankDataTypeTemplate< T >::readDataFromFile(FILE * fid,
        unsigned int colIdx, unsigned int nWords){
    // read size elements into our vector
    // size is specified in # of words, therefor I need to calculate the
    // number of <datatype> contained in a word
    fread((T* )mpRawData+mPtrOffset[colIdx],
            sizeof(T), (MexSupport::MexUInt32)(nWords*mNElementsPerWord), fid);
    mPtrOffset[colIdx] += (MexSupport::MexUInt32)(nWords*mNElementsPerWord);
}

template< class T >
        void TankDataTypeTemplate< T >::assignToMxArray(mxArray*&rpMxArray){

    if( mpRawData != 0x0) {
        MexSupport::assignToMxArray(mpRawData, mNRow, mNCol, rpMxArray);
        mpRawData = 0x0;
    }   
}

#endif
