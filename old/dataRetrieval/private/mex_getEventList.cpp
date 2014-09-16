#include <string>
#include <vector>
#include <set>
#include <iostream>
#include <algorithm>
#include <cstdio>

#include "mex.h"
#include "matrix.h"

#include "MexSupport.h"

using namespace std;
using namespace MexSupport;

typedef std::set<MexUInt32> EventSetType; 
void print_usage();
void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) 
{

  if (nlhs < 1) {
    print_usage();
    return;
  }

  // PLHS must be assigned or matlab throws an error
  plhs[0] = mxCreateNumericMatrix(0, 0, mxDOUBLE_CLASS, mxREAL);

  if( nrhs != 1) {
    print_usage();
    return;
  }

  if(!mxIsChar(prhs[0]))
  {
    print_usage();
    return;
  }

  char* tsq_filename(0x0);
  char* event(0x0);
  int N = mxGetNumberOfElements(prhs[0]);
  tsq_filename = (char *)mxMalloc((N+1)*sizeof(char));

  if( tsq_filename == 0x0) {
    mexPrintf("Out-of-Memory!!\n");
    return;
  }
  mxGetString(prhs[0], tsq_filename, N+1);

  FILE*  fid      = fopen(tsq_filename,"rb");
  if ( fid == NULL) {
    mexPrintf("Failed to open file: %s.\n", tsq_filename);
    return;
  }

  // # 4-byte words per header entry, from spec
  int n_header_words = 10;
  // The number of headers read at a time, increased buffering will speed things up 
  int n_headers      = 100000;
  // space for raw data
  MexUInt32* buffer    = (MexUInt32 *)mxMalloc(n_headers*n_header_words*sizeof(MexUInt32));
  if( buffer == 0x0) {
    mexPrintf("Out-of-Memory!!\n");
    return;
  }

  // magic numbers from the spec
  int code_ind = 2;

  EventSetType event_set;
  EventSetType::iterator event_insert;

  N = 0;
  MexUInt32 event_code;
  while( !feof(fid)) {
    N = fread(buffer, sizeof(MexUInt32), n_headers*n_header_words, fid)/n_header_words;
    for( int ii = 0; ii < N; ii++)
    {
      event_code   = buffer[code_ind+n_header_words*ii];
      // For some reason event codes 0,1,2 appear, but these dont correspond to any
      // real event
      if (event_code > 2 )
      {
          event_set.insert(event_code); 
      }
    }
  }

  fclose(fid);
  int nEvents = event_set.size();

  // Dealloc null array that was allocated at the outset
  mxDestroyArray(plhs[0]);
  plhs[0] = mxCreateCellMatrix(1,nEvents);

  EventSetType::const_iterator set_iter = event_set.begin();
  EventSetType::const_iterator set_end  = event_set.end();
  int ii = 0;
  for( ; set_iter != set_end; set_iter++ )
  {

    // The Event name is stored a 4-byte word.  It is recovered by 
    // masking the bytes off,shifting each towards 0, and then casting
    // to a character
    const char event_name[] = {
    // MJB added static_cast<char>(). This is a narrowing conversion bullshit,
    // which are now errors in C++11. http://stackoverflow.com/questions/4434140
    static_cast<char>((*set_iter & 0x000000FF)),
    static_cast<char>((*set_iter & 0x0000FF00) >> 8),
    static_cast<char>((*set_iter & 0x00FF0000) >> 16),
    static_cast<char>((*set_iter & 0xFF000000) >> 24),
    '\0'};
    mxArray* this_cell = mxGetCell(plhs[0],ii);
    // cells are created null, no need to dealloc
    this_cell = mxCreateString(event_name);
    mxSetCell(plhs[0], ii, this_cell);
    ii++;
  }
  mxFree(tsq_filename);

  // play nice with udders
  mxFree(buffer);
  return;
}

// print usage for slow people
void print_usage() {
  mexPrintf("[events] = GetEventList(TSQ-path);\n");
  return;
}
