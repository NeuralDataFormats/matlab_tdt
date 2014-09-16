#ifndef TANK_DATA_TYPE_H
#define TANK_DATA_TYPE_H

#include <cstdio>
#include "matrix.h"

class TankDataType{
public:
    
    virtual ~TankDataType();

    // @brief Reads data from TEV File
    // @param fid - TEV file pointer
    // @param colIdx - column index within this matrix, as decided by channel number
    // @param nWords - # of words to read
    virtual void readDataFromFile(FILE * fid, unsigned int colIdx, unsigned int nWords) = 0;
    
    // @brief retrieve the number of array elements are in a word
    virtual float getNElementsPerWord() const = 0;
    
    // @brief Assign internal data to an mxArray for output. Abstact interface
    // @param rpMxArray array to contain memory, any existing data will be cleared
    virtual void assignToMxArray(mxArray*& rpMxArray) = 0;
    
    // number of rows in mpRawData
    unsigned int mNRow;
    
    // number of col in mpRawData
    unsigned int mNCol;
protected:

        TankDataType();
    
private:
    
    TankDataType(const TankDataType&);
    
    TankDataType& operator=(const TankDataType&);
};
#endif