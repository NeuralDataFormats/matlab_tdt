#ifndef READ_TANK_H
#define READ_TANK_H
#include <string>
#include <vector>
#include "TDTDataTypes.h"
#include "MexDataTypes.h"
class TankHeaderType;
struct ChannelEntryType;

// Translates a four characters string to a little endian word
// used to match event names to header entries
// @param string - 4 character string to convert, e.g. "LFPs"
// @param word - integer equivalent of string
// @return bool - whether or not translation succeeded
bool translate_string_to_word(const char* string,
        MexSupport::MexUInt32 &word);

// reads table file, populates index which is used to access TEV file
// @param filename - full path to .tsq file
// @param event - name of event to match, e.g. "LFPs"
// @param rTankHeader - structure to return header info in
// @see TankFormat.pdf
int read_tsq_file(const std::string &filename,
        const std::string &event,
        TankHeaderType &rTankHeader);

// reads event file, populates raw data
// @param filename - full path to .tev file
// @param rTankHeader - structure containing header info, location of returned events
// @see TankFormat.pdf
int read_tev_file(const std::string &filename,
        TankHeaderType &rTankHeader);

#endif
