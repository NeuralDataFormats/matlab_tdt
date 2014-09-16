#include "mex.h"
#include "matrix.h"
#include <algorithm>
#include <exception>

#include "TankHeaderType.h"
#include "TankDataTypeTemplate.h"
#include "ReadTank.h"
#include "MexSupport.h"

using namespace std;
using namespace TDTDataTypes;
using namespace MexSupport;
void print_usage();

/*
 * MEX_GETCONTINUOUSDATA gets Continuous data from a single TDT Tank
 * channel_data = mex_get_lfps_from_tank(tsq_filename, tev_filename, lfp_event, channels)
 *
 * INPUTS
 * ========================================================================
 * tsq_filename - (string)  full path to tsq file
 * tev_filename - (string)  full path to tev file
 * event        - (string)  4 Character event name, e.g. LFPs
 * channels     - (numeric) list of channels to retrieve
 *
 * OUTPUTS
 * ========================================================================
 *  data - (numeric) nSamples x nChannels array of data, empty on failure
 *  channels - (numeric)(optional) the channel number of each column in data
 */
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
    // I don't work for free, guy
    if (nlhs < 1) {
        print_usage();
        return;
    }
    
    // PLHS must be assigned or matlab throws an error
    plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
    if(nlhs == 2) {
        plhs[1] = mxCreateDoubleMatrix(0, 0, mxREAL);
    }
    
    if( nrhs != 4) {
        print_usage();
        return;
    }
    
    if(!mxIsChar(prhs[0])
    || !mxIsChar(prhs[1])
    || !mxIsChar(prhs[2])
    || !mxIsNumeric(prhs[3])) {
        print_usage();
        return;
    }
    
    // parse input data into C++ data types
    // ========================================================================
    // CAA TODO use get data instead
    //
    // initialize variables
    char* tev_filename(0x0);
    char* tsq_filename(0x0);
    char* event(0x0);

    // get length of the string
    int N = mxGetNumberOfElements(prhs[0]);
    // allocate memory for tsq filename
    tsq_filename = (char *)mxMalloc((N+1)*sizeof(char));
    // check if the allocation was successful
    if( tsq_filename == 0x0) {
        mexPrintf("Out-of-Memory!!\n");
        return;
    }
    // transfer string from matlab to c variable
    mxGetString(prhs[0], tsq_filename, N+1);
    
    /// get length of the string
    N = mxGetNumberOfElements(prhs[1]);
    // allocate memory
    tev_filename = (char *)mxMalloc((N+1)*sizeof(char));
    // check if the allocastion was successful
    if( tev_filename == 0x0) {
        mexPrintf("Out-of-Memory!!\n");
        return;
    }
    // transfer string from matlab to c
    mxGetString(prhs[1], tev_filename, N+1);
    
    /// get string length 
    N = mxGetNumberOfElements(prhs[2]);
    // allocate memory
    event = (char *)mxMalloc((N+1)*sizeof(char));
    // check allocation
    if( event == 0x0) {
        mexPrintf("Out-of-Memory!!\n");
        return;
    }
    // transfer string from matlab to c
    mxGetString(prhs[2], event, N+1);
    
    // get number of channels to be retrieved
    int nChan    = mxGetNumberOfElements(prhs[3]);
    // transfer channels to be transferred
    double* channels = mxGetPr(prhs[3]);
    
    // # of header entries to preallocate
    int nReserve = 30000;
    
    // prealloc space for header
    TankHeaderType header;
    
    // properly size channels list
    header.mChannels.resize(nChan, 0);
    // copy channels to retrieved in header
    copy(channels, channels+nChan, header.mChannels.begin());
    
    // resize total size, found and channel entries in header
    header.mTotalSize.resize(nChan, 0);
    header.mFound.resize(nChan, false);
    header.mChannelEntries.reserve(nChan*nReserve);

    // read from header file all the headers for event and place data in header object
    if( read_tsq_file(tsq_filename, event, header) >= 0 ) {
        // read successful
        // if we found any event, read data from tev file
        if ( !header.mFound.empty()
        && read_tev_file(tev_filename, header) >= 0) {
              // read successful
              
              // assign data to the matlab matrix
              header.mpTankData->assignToMxArray(plhs[0]);
              // check if we have two arguments in output
              if(nlhs == 2) {
                  // the list of channels is so small i don't bother with any wizardy
                  // create matlab matrix to hold channel list
                  plhs[1] = mxCreateNumericMatrix(1, header.mChannels.size(), mxDOUBLE_CLASS, mxREAL);
                  // get pointer to second output argument
                  MexDouble* channels_out = (MexDouble*)mxGetData( plhs[1]);
                  // copy channels list from header object to output argument
                  copy(header.mChannels.begin(), header.mChannels.end(), channels_out);
              }
        }
        else {
            // error reading tev data file
            mexErrMsgTxt("Read TEV File Failure\n");
        }
    }
    else {
        // error reading tsq header file
        mexErrMsgTxt("Read TSQ File Failure\n");
    }
    
    // free all the memory
    mxFree(tsq_filename);
    mxFree(tev_filename);
    mxFree(event);
    
    return;
}

// print usage for slow people
void print_usage() {
    mexPrintf("Usage: [lfp_data,channels] = mex_getContinuousData(TSQ-path, TEV-path, event,channel #);\n");
    return;
}
