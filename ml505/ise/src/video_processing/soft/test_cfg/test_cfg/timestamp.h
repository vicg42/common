/*
 *	file:		timestamp.h
 *	date:		24.09.2010
 *	authors:	Topolsky
 *	company:	Linkos
 *	format:		tab4
 *	descript.:	Linkos devices hardware-controlled timestamp (of uint32_t type)
 *				service functions
 */

#ifndef __LDCU_TIMESTAMP_H
#define __LDCU_TIMESTAMP_H

#include <stdint.h>

#include <cstddef>

#include <QTime>

namespace Linkos
{
namespace DCU
{
namespace Timestamp
{
	/** Timestamp operations */

	void	SetInvalid(uint32_t *);

	bool	IsInvalid(uint32_t);

	/** Makes the timestamp value from <QTime> (up to msec. precision);
	  * additionaly <husec> (hundred microseconds) and <next_day> flag can be
	  * added to result. If <QTime> argument isn't a valid time result is
	  * invalid */

	uint32_t Make(const QTime &, size_t husec = 0, bool next_day = false);

	/** Converts the timestamp value to <QTime> (up to msec. precision);
	  * additionaly fills non-zero pointees with "hundred microseconds"
	  * (<p_husec>) and "next_day" flag (<p_next_day>). If <p_husec> is null
	  * "husec" value is included in result ("msec." value can be incrmeneted).
	  * Note that if <timestamp> argument is invalid result is a "null time" */

	QTime	Convert(uint32_t timestamp, size_t * p_husec = 0, bool * p_next_day = 0);

} // namespace Timestamp
} // namespace DCU
} // namespace Linkos

#endif // __LDCU_TIMESTAMP_H
