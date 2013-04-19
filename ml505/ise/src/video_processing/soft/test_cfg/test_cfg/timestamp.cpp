/*
 *	file:		timestamp.cpp
 *	date:		24.09.2010
 *	authors:	Topolsky
 *	company:	Linkos
 *	format:		tab4
 */

#include "timestamp.h"

namespace Linkos
{
namespace DCU
{
namespace Timestamp
{
/** Extra declarations ------------------------------------------------------ */

namespace
{
	const size_t HUSEC_OFFSET = 0;
	const uint32_t HUSEC_MASK = (0x0000000f << HUSEC_OFFSET);

	const size_t MSEC_OFFSET = 4;
	const uint32_t MSEC_MASK = (0x000003ff << MSEC_OFFSET);

	const size_t SEC_OFFSET = 14;
	const uint32_t SEC_MASK = (0x0000003f << SEC_OFFSET);

	const size_t MIN_OFFSET = 20;
	const uint32_t MIN_MASK = (0x0000003f << MIN_OFFSET);

	const size_t HOUR_OFFSET = 26;
	const uint32_t HOUR_MASK = (0x0000001f << HOUR_OFFSET);

	const uint32_t NEXTDAY = (0x00000001 << 31);

	const uint32_t INVALID = 0xffffffff;

} // namespace <unnamed>

/** Implementation ---------------------------------------------------------- */

void SetInvalid(uint32_t * ptimestamp)
{
	if (ptimestamp)
		*ptimestamp = INVALID;
}

bool IsInvalid(uint32_t ptimestamp)
{
	return (ptimestamp == INVALID);
}

uint32_t Make(const QTime & time, size_t husec, bool next_day)
{
	if (!time.isValid())
		return INVALID;

	uint32_t timestamp = 0;

	timestamp |= (static_cast<uint32_t>(husec) << HUSEC_OFFSET) & HUSEC_MASK;
	timestamp |= (static_cast<uint32_t>(time.msec()) << MSEC_OFFSET) & MSEC_MASK;
	timestamp |= (static_cast<uint32_t>(time.second()) << SEC_OFFSET) & SEC_MASK;
	timestamp |= (static_cast<uint32_t>(time.minute()) << MIN_OFFSET) & MIN_MASK;
	timestamp |= (static_cast<uint32_t>(time.hour()) << HOUR_OFFSET) & HOUR_MASK;

	if (next_day)
		timestamp |= NEXTDAY;

	return timestamp;
}

QTime Convert(uint32_t timestamp, size_t * p_husec, bool * p_next_day)
{
	const uint32_t next_day = (timestamp & NEXTDAY) ? 1 : 0;
	const uint32_t hour = (timestamp & HOUR_MASK) >> HOUR_OFFSET;
	const uint32_t min = (timestamp & MIN_MASK) >> MIN_OFFSET;
	const uint32_t sec = (timestamp & SEC_MASK) >> SEC_OFFSET;
	const uint32_t msec = (timestamp & MSEC_MASK) >> MSEC_OFFSET;
	const uint32_t husec = (timestamp & HUSEC_MASK) >> HUSEC_OFFSET;

	if ((hour > 23) || (min > 59) || (sec > 59) || (msec > 999) || (husec > 9))
		return QTime();

	if (p_husec)
		*p_husec = husec;

	if (p_next_day)
		*p_next_day = (next_day != 0);

	QTime time(hour, min, sec, msec);

	if (!p_husec && (husec > 4))
		time = time.addMSecs(1);

	return time;
}

} // namespace Timestamp
} // namespace DCU
} // namespace Linkos
