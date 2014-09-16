#include <algorithm>
#include <exception>
#include <string>

#include "TankHeaderType.h"
#include "TankDataTypeTemplate.h"
#include "ReadTank.h"
#include "MexDataTypes.h"

using namespace std;
using namespace TDTDataTypes;
using namespace MexSupport;
void print_usage();

int main(int argc, const char *argv[] ) {

	string tsq_filename = "Z:\\RAWDATA\\2009\\20090918_Olympia\\09182009 - Olympia\\Block-133\\09182009 - Olympia_Block-133.tsq";
	string tev_filename = "Z:\\RAWDATA\\2009\\20090918_Olympia\\09182009 - Olympia\\Block-133\\09182009 - Olympia_Block-133.tev";
	string event        = "LFPs";
	int nChan=10;
	double* channels    = (double*)malloc(sizeof(double)*nChan);
	for (int ii=0; ii < 10; ii++)
		channels[ii] = ii+1;

	// # of header entries to preallocate
	int nReserve = 30000;

	// prealloc space for header
	TankHeaderType header;

	header.mChannels.resize(nChan, 0);
	copy(channels, channels+nChan, header.mChannels.begin());

	header.mTotalSize.resize(nChan, 0);
	header.mFound.resize(nChan, false);
	header.mChannelEntries.reserve(nChan*nReserve);

	if( read_tsq_file(tsq_filename.c_str(), event, header) >= 0 ) {
		if ( !header.mFound.empty()
			&& read_tev_file(tev_filename.c_str(), header) >= 0) {
				// free memory I guess
				free(header.mpRawData);
				header.mpRawData = 0x0;
		}

		else {
			printf("Read TEV File Failure\n");
		}
	}
	else {
		printf("Read TSQ File Failure\n");
	}
	free(channels);
	return 0;
}