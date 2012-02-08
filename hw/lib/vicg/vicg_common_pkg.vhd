-------------------------------------------------------------------------
-- Company     : Telemix
-- Engineer    : Golovachenko Victor
--
-- Create Date : 10/26/2007
-- Module Name :
--
-- Description :
--
-- Revision:
-- Revision 0.01 - File Created
--
---------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-- need conversion function to convert reals/integers to std logic vectors
use ieee.std_logic_arith.conv_std_logic_vector;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library std;
use std.textio.all;

package vicg_common_pkg is

--constant C_ON        : std_logic:='1';
--constant C_OFF       : std_logic:='0';
--constant C_YES       : std_logic:='1';
--constant C_NO        : std_logic:='0';

constant C_1KB         : integer:=1024;
constant C_1MB         : integer:=C_1KB*C_1KB;
constant C_1GB         : integer:=C_1MB*C_1KB;

-------------------------------------------------------------------------------
-- Type Declarations
-------------------------------------------------------------------------------
type TARGET_FAMILY_TYPE is (VIRTEX, VIRTEXII);
type TChar2Int is array (character) of integer;
-- type INTEGER_ARRAY_TYPE is array (natural range <>) of integer;
-- Type SLV64_ARRAY_TYPE is array (natural range <>) of std_logic_vector(0 to 63);

type TInt2Char is array (0 to 15) of character;
constant Int2StrHEX : TInt2Char:=(
'0','1','2','3','4','5','6','7',
'8','9','A','B','C','D','E','F');

-------------------------------------------------------------------------------
-- Function and Procedure Declarations
-------------------------------------------------------------------------------
procedure p_SIM_STOP (constant massage :in string);
procedure p_SIM_ERROR (constant massage :in string);
procedure p_SIM_WARNING (constant massage :in string);

function CONV_STRING( val : in integer) return string;

function crc32_0( Data: std_logic_vector(31 downto 0); CRC: std_logic_vector(31 downto 0) ) return std_logic_vector;
function srambler32_0( FB : std_logic_vector(15 downto 0) ) return std_logic_vector;

function selstring (valtrue, valfalse : string; sel :boolean) return string;
function selval (valtrue, valfalse : integer; sel :boolean) return integer;
function cmpval (val1, val2 : integer) return boolean;

function selval_real (valtrue, valfalse : real; sel :boolean) return real;

--function cmpval2 (val1, val2 : integer) return integer;
function selval2 (val3, val2, val1, val0 : integer; sel1,sel0 :boolean) return integer;

function max2 (num1, num2 : integer) return integer;
function Addr_Bits(x,y : std_logic_vector) return integer;
function pad_power2 ( in_num : integer )  return integer;
function pad_4 ( in_num : integer )  return integer;
function log2(x : natural) return integer;
function pwr(x: integer; y: integer) return integer;
--function Get_RLOC_Name (Target : TARGET_FAMILY_TYPE;
--                          Y      : integer;
--                          X      : integer) return string;
--function Get_Reg_File_Area (Target : TARGET_FAMILY_TYPE) return natural;
function String2Int(S : string) return integer;
function itoa (int : integer) return string;

function toLowerCaseChar( char : character ) return character;
function strcmp( str1, str2 : string ) return boolean;
function strcmp2( str1, str2 : string ) return std_logic;
-------------------------------------------------------------------------------
-- Constant Declarations
-------------------------------------------------------------------------------
-- the RESET_ACTIVE constant should denote the logic level of an active reset
constant RESET_ACTIVE       : std_logic         := '1';

-- table containing strings representing hex characters for conversion to
-- integers
constant StrHEX2Int : TChar2Int :=
    ('0'     => 0,
     '1'     => 1,
     '2'     => 2,
     '3'     => 3,
     '4'     => 4,
     '5'     => 5,
     '6'     => 6,
     '7'     => 7,
     '8'     => 8,
     '9'     => 9,
     'A'|'a' => 10,
     'B'|'b' => 11,
     'C'|'c' => 12,
     'D'|'d' => 13,
     'E'|'e' => 14,
     'F'|'f' => 15,
     others  => -1);

--type INT_TO_CHAR_TYPE is array (0 to 15) of character;
--
--constant INT_TO_STRHEX_TABLE : INT_TO_CHAR_TYPE :=(
--'0',
--'1',
--'2',
--'3',
--'4',
--'5',
--'6',
--'7',
--'8',
--'9',
--'A',
--'B',
--'C',
--'D',
--'E',
--'F'
--);

end vicg_common_pkg;

package body vicg_common_pkg is
-------------------------------------------------------------------------------
-- Function Definitions
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Function f_nextCRC32_D32
--
-- Реализует алгоритм расчета маски скремблирования описатый в
-- d1532v3r4b ATA-ATAPI-7.pdf. /G.1 CRC calculation /page 253
--
-- Data - входные данные
-- CRC - обратная связь: связь с выходом функции
-- Пример i_crc_calc<=crc32_0(p_in_data, i_crc_calc);
-------------------------------------------------------------------------------
function crc32_0(
  Data:  std_logic_vector(31 downto 0);
  CRC :  std_logic_vector(31 downto 0) )
return std_logic_vector is

--  variable D     : std_logic_vector(31 downto 0);
  variable crc_bit: std_logic_vector(31 downto 0);
  variable new_bit: std_logic_vector(31 downto 0);

begin

--D := Data;
--C := CRC;

--/* This sample code reads standard in for a sequence of 32 bit values       */
--/* formatted in hexadecimal with a leading "0x" (e.g. 0xDEADBEEF).  The     */
--/* code calculates the serial ATA CRC for the input data stream.  The       */
--/* generator polynomial used is:                                            */
--/*         32   26   23   22   16   12   11   10   8   7   5   4   2        */
--/* G(x) = x  + x  + x  + x  + x  + x  + x  + x  + x + x + x + x + x + x + 1 */
--/*                                                                          */
--/* This sample code uses a parallel implementation of the CRC calculation   */
--/* circuit that is suitable for implementation in hardware.  A block        */
--/* diagram of the circuit being emulated is shown below.                    */
--/*                                                                          */
--/*                     +---+          +---+          +---+                  */
--/*   Data_In --------->|   |          |   |          | R |                  */
--/*                     | + |--------->| * |--------->| e |----+             */
--/*               +---->|   |          |   |          | g |    |             */
--/*               |     +---+          +---+          +---+    |             */
--/*               |                                            |             */
--/*               |                                            |             */
--/*               +--------------------------------------------+             */
--/*                                                                          */
--/* The CRC value is initialized to 0x52325032                               */
--/*                                                                          */

  for i in 0 to 31 loop -- for loop for XST
    crc_bit(i) := CRC(i) xor Data(i);
  end loop;

--  /* The following 32 assignments perform the function of the box       */
--  /* labeled "*" in the block diagram above.  The new_bit array is a    */
--  /* temporary holding place for the new CRC value being calculated.    */
--  /* Note that there are lots of shared terms in the assignments below. */
  new_bit(31) := crc_bit(31) xor crc_bit(30) xor crc_bit(29) xor crc_bit(28) xor crc_bit(27) xor crc_bit(25) xor crc_bit(24) xor  crc_bit(23) xor crc_bit(15) xor crc_bit(11) xor crc_bit(9)  xor crc_bit(8)  xor crc_bit(5);
  new_bit(30) := crc_bit(30) xor crc_bit(29) xor crc_bit(28) xor crc_bit(27) xor crc_bit(26) xor crc_bit(24) xor crc_bit(23) xor  crc_bit(22) xor crc_bit(14) xor crc_bit(10) xor crc_bit(8)  xor crc_bit(7)  xor crc_bit(4);
  new_bit(29) := crc_bit(31) xor crc_bit(29) xor crc_bit(28) xor crc_bit(27) xor crc_bit(26) xor crc_bit(25) xor crc_bit(23) xor  crc_bit(22) xor crc_bit(21) xor crc_bit(13) xor crc_bit(9)  xor crc_bit(7)  xor crc_bit(6)  xor crc_bit(3);
  new_bit(28) := crc_bit(30) xor crc_bit(28) xor crc_bit(27) xor crc_bit(26) xor crc_bit(25) xor crc_bit(24) xor crc_bit(22) xor  crc_bit(21) xor crc_bit(20) xor crc_bit(12) xor crc_bit(8)  xor crc_bit(6)  xor crc_bit(5)  xor crc_bit(2);
  new_bit(27) := crc_bit(29) xor crc_bit(27) xor crc_bit(26) xor crc_bit(25) xor crc_bit(24) xor crc_bit(23) xor crc_bit(21) xor  crc_bit(20) xor crc_bit(19) xor crc_bit(11) xor crc_bit(7)  xor crc_bit(5)  xor crc_bit(4)  xor crc_bit(1);
  new_bit(26) := crc_bit(31) xor crc_bit(28) xor crc_bit(26) xor crc_bit(25) xor crc_bit(24) xor crc_bit(23) xor crc_bit(22) xor  crc_bit(20) xor crc_bit(19) xor crc_bit(18) xor crc_bit(10) xor crc_bit(6)  xor crc_bit(4)  xor crc_bit(3)  xor  crc_bit(0);
  new_bit(25) := crc_bit(31) xor crc_bit(29) xor crc_bit(28) xor crc_bit(22) xor crc_bit(21) xor crc_bit(19) xor crc_bit(18) xor  crc_bit(17) xor crc_bit(15) xor crc_bit(11) xor crc_bit(8)  xor crc_bit(3)  xor crc_bit(2);
  new_bit(24) := crc_bit(30) xor crc_bit(28) xor crc_bit(27) xor crc_bit(21) xor crc_bit(20) xor crc_bit(18) xor crc_bit(17) xor  crc_bit(16) xor crc_bit(14) xor crc_bit(10) xor crc_bit(7)  xor crc_bit(2)  xor crc_bit(1);
  new_bit(23) := crc_bit(31) xor crc_bit(29) xor crc_bit(27) xor crc_bit(26) xor crc_bit(20) xor crc_bit(19) xor crc_bit(17) xor  crc_bit(16) xor crc_bit(15) xor crc_bit(13) xor crc_bit(9)  xor crc_bit(6)  xor crc_bit(1)  xor crc_bit(0);
  new_bit(22) := crc_bit(31) xor crc_bit(29) xor crc_bit(27) xor crc_bit(26) xor crc_bit(24) xor crc_bit(23) xor crc_bit(19) xor  crc_bit(18) xor crc_bit(16) xor crc_bit(14) xor crc_bit(12) xor crc_bit(11) xor crc_bit(9)  xor crc_bit(0);
  new_bit(21) := crc_bit(31) xor crc_bit(29) xor crc_bit(27) xor crc_bit(26) xor crc_bit(24) xor crc_bit(22) xor crc_bit(18) xor  crc_bit(17) xor crc_bit(13) xor crc_bit(10) xor crc_bit(9)  xor crc_bit(5);
  new_bit(20) := crc_bit(30) xor crc_bit(28) xor crc_bit(26) xor crc_bit(25) xor crc_bit(23) xor crc_bit(21) xor crc_bit(17) xor  crc_bit(16) xor crc_bit(12) xor crc_bit(9)  xor crc_bit(8)  xor crc_bit(4);
  new_bit(19) := crc_bit(29) xor crc_bit(27) xor crc_bit(25) xor crc_bit(24) xor crc_bit(22) xor crc_bit(20) xor crc_bit(16) xor  crc_bit(15) xor crc_bit(11) xor crc_bit(8)  xor crc_bit(7)  xor crc_bit(3);
  new_bit(18) := crc_bit(31) xor crc_bit(28) xor crc_bit(26) xor crc_bit(24) xor crc_bit(23) xor crc_bit(21) xor crc_bit(19) xor  crc_bit(15) xor crc_bit(14) xor crc_bit(10) xor crc_bit(7)  xor crc_bit(6)  xor crc_bit(2);
  new_bit(17) := crc_bit(31) xor crc_bit(30) xor crc_bit(27) xor crc_bit(25) xor crc_bit(23) xor crc_bit(22) xor crc_bit(20) xor  crc_bit(18) xor crc_bit(14) xor crc_bit(13) xor crc_bit(9)  xor crc_bit(6)  xor crc_bit(5)  xor crc_bit(1);
  new_bit(16) := crc_bit(30) xor crc_bit(29) xor crc_bit(26) xor crc_bit(24) xor crc_bit(22) xor crc_bit(21) xor crc_bit(19) xor  crc_bit(17) xor crc_bit(13) xor crc_bit(12) xor crc_bit(8)  xor crc_bit(5)  xor crc_bit(4)  xor crc_bit(0);
  new_bit(15) := crc_bit(30) xor crc_bit(27) xor crc_bit(24) xor crc_bit(21) xor crc_bit(20) xor crc_bit(18) xor crc_bit(16) xor  crc_bit(15) xor crc_bit(12) xor crc_bit(9)  xor crc_bit(8)  xor crc_bit(7)  xor crc_bit(5)  xor crc_bit(4)  xor  crc_bit(3);
  new_bit(14) := crc_bit(29) xor crc_bit(26) xor crc_bit(23) xor crc_bit(20) xor crc_bit(19) xor crc_bit(17) xor crc_bit(15) xor  crc_bit(14) xor crc_bit(11) xor crc_bit(8)  xor crc_bit(7)  xor crc_bit(6)  xor crc_bit(4)  xor crc_bit(3)  xor  crc_bit(2);
  new_bit(13) := crc_bit(31) xor crc_bit(28) xor crc_bit(25) xor crc_bit(22) xor crc_bit(19) xor crc_bit(18) xor crc_bit(16) xor  crc_bit(14) xor crc_bit(13) xor crc_bit(10) xor crc_bit(7)  xor crc_bit(6)  xor crc_bit(5)  xor crc_bit(3)  xor  crc_bit(2)  xor crc_bit(1);
  new_bit(12) := crc_bit(31) xor crc_bit(30) xor crc_bit(27) xor crc_bit(24) xor crc_bit(21) xor crc_bit(18) xor crc_bit(17) xor  crc_bit(15) xor crc_bit(13) xor crc_bit(12) xor crc_bit(9)  xor crc_bit(6)  xor crc_bit(5)  xor crc_bit(4)  xor  crc_bit(2)  xor crc_bit(1)  xor crc_bit(0);
  new_bit(11) := crc_bit(31) xor crc_bit(28) xor crc_bit(27) xor crc_bit(26) xor crc_bit(25) xor crc_bit(24) xor crc_bit(20) xor  crc_bit(17) xor crc_bit(16) xor crc_bit(15) xor crc_bit(14) xor crc_bit(12) xor crc_bit(9)  xor crc_bit(4)  xor  crc_bit(3)  xor crc_bit(1)  xor crc_bit(0);
  new_bit(10) := crc_bit(31) xor crc_bit(29) xor crc_bit(28) xor crc_bit(26) xor crc_bit(19) xor crc_bit(16) xor crc_bit(14) xor  crc_bit(13) xor crc_bit(9)  xor crc_bit(5)  xor crc_bit(3)  xor crc_bit(2)  xor crc_bit(0);
  new_bit(9)  := crc_bit(29) xor crc_bit(24) xor crc_bit(23) xor crc_bit(18) xor crc_bit(13) xor crc_bit(12) xor crc_bit(11) xor  crc_bit(9)  xor crc_bit(5)  xor crc_bit(4)  xor crc_bit(2)  xor crc_bit(1);
  new_bit(8)  := crc_bit(31) xor crc_bit(28) xor crc_bit(23) xor crc_bit(22) xor crc_bit(17) xor crc_bit(12) xor crc_bit(11) xor  crc_bit(10) xor crc_bit(8)  xor crc_bit(4)  xor crc_bit(3)  xor crc_bit(1)  xor crc_bit(0);
  new_bit(7)  := crc_bit(29) xor crc_bit(28) xor crc_bit(25) xor crc_bit(24) xor crc_bit(23) xor crc_bit(22) xor crc_bit(21) xor  crc_bit(16) xor crc_bit(15) xor crc_bit(10) xor crc_bit(8)  xor crc_bit(7)  xor crc_bit(5)  xor crc_bit(3)  xor crc_bit(2)  xor crc_bit(0);
  new_bit(6)  := crc_bit(30) xor crc_bit(29) xor crc_bit(25) xor crc_bit(22) xor crc_bit(21) xor crc_bit(20) xor crc_bit(14) xor  crc_bit(11) xor crc_bit(8)  xor crc_bit(7)  xor crc_bit(6)  xor crc_bit(5)  xor crc_bit(4)  xor crc_bit(2)  xor crc_bit(1);
  new_bit(5)  := crc_bit(29) xor crc_bit(28) xor crc_bit(24) xor crc_bit(21) xor crc_bit(20) xor crc_bit(19) xor crc_bit(13) xor  crc_bit(10) xor crc_bit(7)  xor crc_bit(6)  xor crc_bit(5)  xor crc_bit(4)  xor crc_bit(3)  xor crc_bit(1)  xor crc_bit(0);
  new_bit(4)  := crc_bit(31) xor crc_bit(30) xor crc_bit(29) xor crc_bit(25) xor crc_bit(24) xor crc_bit(20) xor crc_bit(19) xor  crc_bit(18) xor crc_bit(15) xor crc_bit(12) xor crc_bit(11) xor crc_bit(8)  xor crc_bit(6)  xor crc_bit(4)  xor crc_bit(3)  xor crc_bit(2)  xor crc_bit(0);
  new_bit(3)  := crc_bit(31) xor crc_bit(27) xor crc_bit(25) xor crc_bit(19) xor crc_bit(18) xor crc_bit(17) xor crc_bit(15) xor  crc_bit(14) xor crc_bit(10) xor crc_bit(9)  xor crc_bit(8)  xor crc_bit(7)  xor crc_bit(3)  xor crc_bit(2)  xor crc_bit(1);
  new_bit(2)  := crc_bit(31) xor crc_bit(30) xor crc_bit(26) xor crc_bit(24) xor crc_bit(18) xor crc_bit(17) xor crc_bit(16) xor  crc_bit(14) xor crc_bit(13) xor crc_bit(9)  xor crc_bit(8)  xor crc_bit(7)  xor crc_bit(6)  xor crc_bit(2)  xor crc_bit(1)  xor crc_bit(0);
  new_bit(1)  := crc_bit(28) xor crc_bit(27) xor crc_bit(24) xor crc_bit(17) xor crc_bit(16) xor crc_bit(13) xor crc_bit(12) xor  crc_bit(11) xor crc_bit(9)  xor crc_bit(7)  xor crc_bit(6)  xor crc_bit(1)  xor crc_bit(0);
  new_bit(0)  := crc_bit(31) xor crc_bit(30) xor crc_bit(29) xor crc_bit(28) xor crc_bit(26) xor crc_bit(25) xor crc_bit(24) xor  crc_bit(16) xor crc_bit(12) xor crc_bit(10) xor crc_bit(9)  xor crc_bit(6)  xor crc_bit(0);

return new_bit;

end crc32_0;

-------------------------------------------------------------------------------
-- Function f_sata_srambler
--
-- Реализует алгоритм расчета маски скремблирования описатый в
-- d1532v3r4b ATA-ATAPI-7.pdf. /G.2 Scrambling calculation /page 257
--
-- FB - обратная связь: Связь со старшей частью выхода функции
-- Пример i_srambler_out<=srambler32_0(i_srambler_out(31 downto 16));
-------------------------------------------------------------------------------
function srambler32_0( FB :  std_logic_vector(15 downto 0) )
return std_logic_vector is

  variable now     : std_logic_vector(15 downto 0);
  variable new_bit : std_logic_vector(31 downto 0);

begin

now := FB;

--
--/* This sample code generates the entire sequence of 65535 DWORDs produced  */
--/* by the scrambler defined in this standard.  The                          */
--/* standard calls for an LFSR to generate a string of bits that will       */
--/* be packaged into 32 bit DWORDs to be XORed with the data DWORDs.  The    */
--/* generator polynomial specified is:                                       */
--/*                          16   15   13   4                                */
--/*                  G(x) = x  + x  + x  + x + 1                             */
--/*                                                                          */
--/* Parallelized versions of the scrambler are initialized to a value        */
--/* derived from the initialization value of 0xFFFF defined in the           */
--/* standard.  This implementation is initialized to 0xF0F6.  Other          */
--/* parallel implementations will have different initial values.  The       */
--/* important point is that the first DWORD output of any implementation     */
--/* shall equal 0xC2D2768D.                                                 */
--/*                                                                          */
--/* This code does not represent an elegant solution for a C implementation, */
--/* but it does demonstrate a method of generating the sequence that can be  */
--/* easily implemented in hardware.  A block diagram of the circuit emulated */
--/* by this code is shown below.                                             */
--/*                                                                          */
--/*         +-----------------------------------+                            */
--/*         |                                   |                            */
--/*         |                                   |                            */
--/*         |     +---+                +---+    |                            */
--/*         |     | R |                | * |    |                            */
--/*         +---->| e |----------+---->| M |----+----> Output(31 downto 16)  */
--/*               | g |          |     | 1 |                                 */
--/*               +---+          |     +---+                                 */
--/*                              |                                           */
--/*                              |     +---+                                 */
--/*                              |     | * |                                 */
--/*                              +---->| M |---------> Output(15 downto 0)   */
--/*                                    | 2 |                                 */
--/*                                    +---+                                 */
--/*                                                                          */
--/* The register shown in the block diagram is a 16 bit register.  The two   */
--/* boxes, *M1 and *M2, each represent a multiply by a 16 by 16 binary       */
--/* matrix.  A 16 by 16 matrix times a 16 bit vector yields a 16 bit vector. */
--/* The two vectors are the two halves of the 32 bit scrambler value.  The   */
--/* upper half of the scrambler value is stored back into the context        */
--/* register to be used to generate the next value in the scrambler          */
--/* sequence.                                                                */
--/*                                                                          */
--
--  /* The following 16 assignments implement the matrix multiplication   */
--  /* performed by the box labeled *M1.                                  */
--  /* Notice that there are lots of shared terms in these assignments.   */
  new_bit(31) := now(12) xor now(10) xor now(7)  xor now(3)  xor now(1)  xor now(0);
  new_bit(30) := now(15) xor now(14) xor now(12) xor now(11) xor now(9)  xor now(6)  xor now(3)  xor now(2)  xor now(0);
  new_bit(29) := now(15) xor now(13) xor now(12) xor now(11) xor now(10) xor now(8)  xor now(5)  xor now(3)  xor now(2)  xor now(1);
  new_bit(28) := now(14) xor now(12) xor now(11) xor now(10) xor now(9)  xor now(7)  xor now(4)  xor now(2)  xor now(1)  xor now(0);
  new_bit(27) := now(15) xor now(14) xor now(13) xor now(12) xor now(11) xor now(10) xor now(9)  xor now(8)  xor now(6)  xor now(1)  xor now(0);
  new_bit(26) := now(15) xor now(13) xor now(11) xor now(10) xor now(9)  xor now(8)  xor now(7)  xor now(5)  xor now(3)  xor now(0);
  new_bit(25) := now(15) xor now(10) xor now(9)  xor now(8)  xor now(7)  xor now(6)  xor now(4)  xor now(3)  xor now(2);
  new_bit(24) := now(14) xor now(9)  xor now(8)  xor now(7)  xor now(6)  xor now(5)  xor now(3)  xor now(2)  xor now(1);
  new_bit(23) := now(13) xor now(8)  xor now(7)  xor now(6)  xor now(5)  xor now(4)  xor now(2)  xor now(1)  xor now(0);
  new_bit(22) := now(15) xor now(14) xor now(7)  xor now(6)  xor now(5)  xor now(4)  xor now(1)  xor now(0);
  new_bit(21) := now(15) xor now(13) xor now(12) xor now(6)  xor now(5)  xor now(4)  xor now(0);
  new_bit(20) := now(15) xor now(11) xor now(5)  xor now(4);
  new_bit(19) := now(14) xor now(10) xor now(4)  xor now(3);
  new_bit(18) := now(13) xor now(9)  xor now(3)  xor now(2);
  new_bit(17) := now(12) xor now(8)  xor now(2)  xor now(1);
  new_bit(16) := now(11) xor now(7)  xor now(1)  xor now(0);

--  /* The following 16 assignments implement the matrix multiplication   */
--  /* performed by the box labeled *M2.                                  */
  new_bit(15) := now(15) xor now(14) xor now(12) xor now(10) xor now(6)  xor now(3)  xor now(0);
  new_bit(14) := now(15) xor now(13) xor now(12) xor now(11) xor now(9)  xor now(5)  xor now(3)  xor now(2);
  new_bit(13) := now(14) xor now(12) xor now(11) xor now(10) xor now(8)  xor now(4)  xor now(2)  xor now(1);
  new_bit(12) := now(13) xor now(11) xor now(10) xor now(9)  xor now(7)  xor now(3)  xor now(1)  xor now(0);
  new_bit(11) := now(15) xor now(14) xor now(10) xor now(9)  xor now(8)  xor now(6)  xor now(3)  xor now(2)  xor now(0);
  new_bit(10) := now(15) xor now(13) xor now(12) xor now(9)  xor now(8)  xor now(7)  xor now(5)  xor now(3)  xor now(2)  xor now(1);
  new_bit(9)  := now(14) xor now(12) xor now(11) xor now(8)  xor now(7)  xor now(6)  xor now(4)  xor now(2)  xor now(1)  xor now(0);
  new_bit(8)  := now(15) xor now(14) xor now(13) xor now(12) xor now(11) xor now(10) xor now(7)  xor now(6)  xor now(5)  xor now(1)  xor now(0);
  new_bit(7)  := now(15) xor now(13) xor now(11) xor now(10) xor now(9)  xor now(6)  xor now(5)  xor now(4)  xor now(3)  xor now(0);
  new_bit(6)  := now(15) xor now(10) xor now(9)  xor now(8)  xor now(5)  xor now(4)  xor now(2);
  new_bit(5)  := now(14) xor now(9)  xor now(8)  xor now(7)  xor now(4)  xor now(3)  xor now(1);
  new_bit(4)  := now(13) xor now(8)  xor now(7)  xor now(6)  xor now(3)  xor now(2)  xor now(0);
  new_bit(3)  := now(15) xor now(14) xor now(7)  xor now(6)  xor now(5)  xor now(3)  xor now(2)  xor now(1);
  new_bit(2)  := now(14) xor now(13) xor now(6)  xor now(5)  xor now(4)  xor now(2)  xor now(1)  xor now(0);
  new_bit(1)  := now(15) xor now(14) xor now(13) xor now(5)  xor now(4)  xor now(1)  xor now(0);
  new_bit(0)  := now(15) xor now(13) xor now(4)  xor now(0);

return new_bit;

end srambler32_0;


------------------------------------------------------------------------------
-- Function cmpval
--
--
-------------------------------------------------------------------------------
function cmpval (val1, val2 : integer) return boolean is
  variable equal : boolean := true;
begin
if val1 = val2 then
  equal:=true;
else
  equal:=false;
end if;

return equal;
end function cmpval;

-------------------------------------------------------------------------------
-- Function selstring
--
--
-------------------------------------------------------------------------------
function selstring (valtrue, valfalse : string; sel :boolean) return string is
begin
if sel=true then
  return valtrue;
else
  return valfalse;
end if;
end function selstring;

-------------------------------------------------------------------------------
-- Function selval
--
--
-------------------------------------------------------------------------------
function selval (valtrue, valfalse : integer; sel :boolean) return integer is
begin
if sel=true then
  return valtrue;
else
  return valfalse;
end if;
end function selval;


-------------------------------------------------------------------------------
-- Function selval_real
--
--
-------------------------------------------------------------------------------
function selval_real (valtrue, valfalse : real; sel :boolean) return real is
begin
if sel=true then
  return valtrue;
else
  return valfalse;
end if;
end function selval_real;
--------------------------------------------------------------------------------
---- Function cmpval2
----
----
---------------------------------------------------------------------------------
--function cmpval2 (val1, val2 : integer) return integer is
--begin
--if val1 = val2 then
--  return 1;
--else
--  return 0;
--end if;
--end function cmpval2;

-------------------------------------------------------------------------------
-- Function selval2
--
--
-------------------------------------------------------------------------------
function selval2 (val3, val2, val1, val0 : integer; sel1,sel0 :boolean) return integer is
begin
if sel1=false and sel0=false then
  return val0;
elsif sel1=false and sel0=true then
  return val1;
elsif sel1=true and sel0=false then
  return val2;
else
  return val3;
end if;
end function selval2;

-------------------------------------------------------------------------------
-- Function max2
--
-- This function returns the greater of two numbers.
-------------------------------------------------------------------------------
function max2 (num1, num2 : integer) return integer is
begin
    if num1 >= num2 then
        return num1;
    else
        return num2;
    end if;
end function max2;

-------------------------------------------------------------------------------
-- Function Addr_bits
--
-- function to convert an address range (base address and an upper address)
-- into the number of upper address bits needed for decoding a device
-- select signal.  will handle slices and big or little endian
-------------------------------------------------------------------------------
function Addr_Bits(x,y : std_logic_vector) return integer is
  variable addr_xor : std_logic_vector(x'range);
  variable count    : integer := 0;
begin
  assert x'length = y'length and (x'ascending xnor y'ascending)
    report "Addr_Bits: arguments are not the same type"
    severity ERROR;
  addr_xor := x xor y;
  for i in x'range
  loop
    if addr_xor(i) = '1' then return count;
    end if;
    count := count + 1;
  end loop;
  return x'length;
end Addr_Bits;

-------------------------------------------------------------------------------
-- Function pad_power2
--
-- This function returns the next power of 2 from the input number. If the
-- input number is a power of 2, this function returns the input number.
--
-- This function is used to round up the number of masters to the next power
-- of 2 if the number of masters is not already a power of 2
-------------------------------------------------------------------------------
--
function pad_power2 (in_num : integer  ) return integer is

  variable i          : integer := 0;
  variable out_num    : integer;

begin
    if in_num = 0 then
        out_num := 0;
    else
--        while 2**i < in_num loop
--            i := i+1;
--       end loop;
-- replace while loop with for loop for XST
        for j in 0 to 8 loop
            if out_num >= in_num then null;
            else
                i := i+1;
                out_num := 2**i;
            end if;
        end loop;
    end if;

    return out_num;
end pad_power2;


-------------------------------------------------------------------------------
-- Function pad_4
--
-- This function returns the next multiple of 4 from the input number. If the
-- input number is a multiple of 4, this function returns the input number.
--
-------------------------------------------------------------------------------
--
function pad_4 (in_num : integer  ) return integer is

variable out_num     : integer;

begin
    out_num := (((in_num-1)/4) + 1)*4;
    return out_num;

end pad_4;

-------------------------------------------------------------------------------
-- Function log2 -- returns number of bits needed to encode x choices
--   x = 0  returns 0
--   x = 1  returns 0
--   x = 2  returns 1
--   x = 4  returns 2, etc.
-------------------------------------------------------------------------------
--
function log2(x : natural) return integer is
  variable i  : integer := 0;
  variable val: integer := 1;
begin
  if x = 0 then return 0;
  else
    for j in 0 to 29 loop -- for loop for XST
      if val >= x then null;
      else
        i := i+1;
        val := val*2;
      end if;
    end loop;
    if val >= x then
      assert true
        report "Function log2 received argument larger" &
               " than its capability of 2^30. "
        severity failure;
    end if;
    return i;
  end if;
end function log2;


-------------------------------------------------------------------------------
-- Function pwr -- x**y
-- negative numbers not allowed for y
-------------------------------------------------------------------------------

function pwr(x: integer; y: integer) return integer is
  variable z : integer := 1;
begin
  if y = 0 then return 1;
  else
    for i in 1 to y loop
      z := z * x;
    end loop;
    return z;
  end if;
end function pwr;

-------------------------------------------------------------------------------
-- Function itoa
--
-- The itoa function converts an integer to a text string.
-- This function is required since `image doesn't work in Synplicity
-- Valid input range is -9999 to 9999
-------------------------------------------------------------------------------
--
function itoa (int : integer) return string is
  type table is array (0 to 9) of string (1 to 1);
  constant LUT     : table :=
    ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9");
  variable str1            : string(1 to 1);
  variable str2            : string(1 to 2);
  variable str3            : string(1 to 3);
  variable str4            : string(1 to 4);
  variable str5            : string(1 to 5);
  variable abs_int         : natural;

  variable thousands_place : natural;
  variable hundreds_place  : natural;
  variable tens_place      : natural;
  variable ones_place      : natural;
  variable sign            : integer;

begin
  abs_int := abs(int);
  if abs_int > int then sign := -1;
  else sign := 1;
  end if;
  thousands_place :=  abs_int/1000;
  hundreds_place :=  (abs_int-thousands_place*1000)/100;
  tens_place :=      (abs_int-thousands_place*1000-hundreds_place*100)/10;
  ones_place :=
    (abs_int-thousands_place*1000-hundreds_place*100-tens_place*10);

  if sign>0 then
    if thousands_place>0 then
      str4 := LUT(thousands_place) & LUT(hundreds_place) & LUT(tens_place) &
              LUT(ones_place);
      return str4;
    elsif hundreds_place>0 then
      str3 := LUT(hundreds_place) & LUT(tens_place) & LUT(ones_place);
      return str3;
    elsif tens_place>0 then
      str2 := LUT(tens_place) & LUT(ones_place);
      return str2;
    else
      str1 := LUT(ones_place);
      return str1;
    end if;
  else
    if thousands_place>0 then
      str5 := "-" & LUT(thousands_place) & LUT(hundreds_place) &
        LUT(tens_place) & LUT(ones_place);
      return str5;
    elsif hundreds_place>0 then
      str4 := "-" & LUT(hundreds_place) & LUT(tens_place) & LUT(ones_place);
      return str4;
    elsif tens_place>0 then
      str3 := "-" & LUT(tens_place) & LUT(ones_place);
      return str3;
    else
      str2 := "-" & LUT(ones_place);
      return str2;
    end if;
  end if;
end itoa;


-------------------------------------------------------------------------------
-- Function Get_RLOC_Name
--
-- This function calculates the proper RLOC value based on the FPGA target
-- family.
-------------------------------------------------------------------------------
--

--  function Get_RLOC_Name (Target : TARGET_FAMILY_TYPE;
--                          Y      : integer;
--                          X      : integer) return string is
--    variable Col : integer;
--    variable Row : integer;
--    variable S : integer;
--  begin
--    if Target = VIRTEX then
--      Row := -Y;
--      Col := X/2;
--      S   := 1 - (X mod 2);
--      return 'R' & itoa(Row) &
--             'C' & itoa(Col) &
--             ".S" & itoa(S);
--    elsif Target = VIRTEXII then
--      return 'X' & itoa(X) & 'Y' & itoa(Y);
--    end if;
--  end Get_RLOC_Name;

-------------------------------------------------------------------------------
-- Function Get_Reg_File_Area
--
-- This function returns the number of slices in x that each bit of the
-- Register_File occupies
-------------------------------------------------------------------------------
--  function Get_Reg_File_Area (Target : TARGET_FAMILY_TYPE) return natural is
--  begin  -- function Get_Y_Area
--    if Target = VIRTEX then
--      return 6;
--    elsif target = VIRTEXII then
--      return 4;
--    end if;
--  end function Get_Reg_File_Area;


-----------------------------------------------------------------------------
-- Function String2Int
--
-- Converts a string of hex character to an integer
-- accept negative numbers
-----------------------------------------------------------------------------
function String2Int(S : String) return Integer is
  variable Result : integer := 0;
  variable Temp   : integer := S'Left;
  variable Negative : integer := 1;
begin
  for I in S'Left to S'Right loop
    -- ASCII value - 42 TBD
    if (S(I) = '-') then
      Temp     := 0;
      Negative := -1;
    else
      Temp := StrHEX2Int(S(I));
      if (Temp = -1) then
        assert false
          report "Wrong value in String2Int conversion " & S(I)
          severity error;
      end if;
    end if;
    Result := Result * 16 + Temp;
  end loop;
  return (Negative * Result);
end String2Int;

-------------------------------------------------------------------------------
-- Function toLowerCaseChar
--
-- Returns the lower case form of char if char is an upper case letter.
-- Otherwise char is returned.
-------------------------------------------------------------------------------
function toLowerCaseChar( char : character ) return character is
begin
-- If char is not an upper case letter then return char
if char < 'A' OR char > 'Z' then
  return char;
end if;
-- Otherwise map char to its corresponding lower case character and
-- return that
case char is
  when 'A' => return 'a';
  when 'B' => return 'b';
  when 'C' => return 'c';
  when 'D' => return 'd';
  when 'E' => return 'e';
  when 'F' => return 'f';
  when 'G' => return 'g';
  when 'H' => return 'h';
  when 'I' => return 'i';
  when 'J' => return 'j';
  when 'K' => return 'k';
  when 'L' => return 'l';
  when 'M' => return 'm';
  when 'N' => return 'n';
  when 'O' => return 'o';
  when 'P' => return 'p';
  when 'Q' => return 'q';
  when 'R' => return 'r';
  when 'S' => return 's';
  when 'T' => return 't';
  when 'U' => return 'u';
  when 'V' => return 'v';
  when 'W' => return 'w';
  when 'X' => return 'x';
  when 'Y' => return 'y';
  when 'Z' => return 'z';
  when others => return char;
end case;
end toLowerCaseChar;

-------------------------------------------------------------------------------
-- Function strcmp
--
-- Returns true if case insensitive string comparison determines that
-- str1 and str2 are equal
-------------------------------------------------------------------------------
function strcmp( str1, str2 : string ) return boolean is
  constant LEN1  : integer := str1'length;
  constant LEN2  : integer := str2'length;
  variable equal : boolean := TRUE;
begin
if not (LEN1 = LEN2) then
  equal := FALSE;
else
  for i in str1'range loop
    if not (toLowerCaseChar(str1(i)) = toLowerCaseChar(str2(i))) then
      equal := FALSE;
    end if;
  end loop;
end if;

return equal;
end strcmp;

-------------------------------------------------------------------------------
-- Function strcmp
--
-- Returns true if case insensitive string comparison determines that
-- str1 and str2 are equal
-------------------------------------------------------------------------------
function strcmp2( str1, str2 : string ) return std_logic is
  constant LEN1  : integer := str1'length;
  constant LEN2  : integer := str2'length;
  variable equal : std_logic := '1';
begin
if not (LEN1 = LEN2) then
  equal := '0';
else
  for i in str1'range loop
    if not (toLowerCaseChar(str1(i)) = toLowerCaseChar(str2(i))) then
      equal := '0';
    end if;
  end loop;
end if;

return equal;
end strcmp2;


-------------------------------------------------------------------------------
--  Proc : FINISH_FAILURE
--  Inputs : Только Анлгийские символы
--  Description : Завершает simulation with failure message
-------------------------------------------------------------------------------
procedure p_SIM_STOP (
  constant massage :in string) is
--  variable  L : line;
begin
  assert (false)
--    report "Simulation Ended With 1 or more failures"
    report massage
    severity failure;--error;--
end p_SIM_STOP;

-------------------------------------------------------------------------------
--  Proc : FINISH_ERROR
--  Inputs : Только Анлгийские символы
--  Description : Места возникновения ошибок при симуляции помечаются КРАСНЫМ цветом
-------------------------------------------------------------------------------
procedure p_SIM_ERROR (
  constant massage :in string) is
--  variable  L : line;
begin
  assert (false)
--    report "Simulation Ended With 1 or more failures"
    report massage
    severity error;--failure;--warning;--note
end p_SIM_ERROR;

-------------------------------------------------------------------------------
--  Proc : FINISH_ERROR
--  Inputs : Только Анлгийские символы
--  Description : Места возникновения пердупреждений при симуляции помечаются ЗЕЛЕНЫМ цветом
-------------------------------------------------------------------------------
procedure p_SIM_WARNING (
  constant massage :in string) is
--  variable  L : line;
begin
  assert (false)
--    report "Simulation Ended With 1 or more failures"
    report massage
    severity warning;--note;--error;--failure;--
end p_SIM_WARNING;


function CONV_STRING(
    val : in integer)
return string is
    variable l : line;
    variable len : integer;
    variable s : string(1 to 64);
begin
    write(l, val);
    len := l'length;
    read(l, s(1 to len));
    return s(1 to len);
end;

end package body vicg_common_pkg;

