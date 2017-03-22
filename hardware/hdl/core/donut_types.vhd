----------------------------------------------------------------------------
----------------------------------------------------------------------------
--
-- Copyright 2016,2017 International Business Machines
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions AND
-- limitations under the License.
--
----------------------------------------------------------------------------
----------------------------------------------------------------------------

LIBRARY ieee;-- ibm, ibm_asic;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
--USE ieee.std_logic_arith.all;
USE work.std_ulogic_support.all;
USE work.std_ulogic_function_support.all;
use work.std_ulogic_unsigned.all;
USE work.psl_accel_types.ALL;

PACKAGE donut_types IS

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** DONUT FUNCTION DEFINITION                  *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  --
  -- verilog <-> vhdl connector
  --
  FUNCTION v2vhdl_connector(CONSTANT data_in :std_ulogic_vector) RETURN std_ulogic_vector;
  FUNCTION vhdl2v_connector(CONSTANT data_in :std_ulogic_vector) RETURN std_ulogic_vector;

  --
  -- Parity Generator
  --
  FUNCTION gen_parity_odd_32(CONSTANT data : IN std_ulogic_vector) RETURN std_ulogic_vector;
  FUNCTION gen_parity_odd_64(CONSTANT data : IN std_ulogic_vector) RETURN std_ulogic_vector;
  FUNCTION gen_parity_odd_128(CONSTANT data : IN std_ulogic_vector) RETURN std_ulogic_vector;
  function AC_GENPARITY(data_in :std_ulogic_vector; w: natural) return std_ulogic_vector;
  function AC_GENPARITY(data_in : std_ulogic_vector           ) return std_ulogic_vector;

  --
  -- Parity Prediction
  --
  function AC_PPARITH(dir: integer; a_in ,ap_in,b_in,bp_in : std_ulogic_vector; w : natural := 8                              ) return std_ulogic_vector;
  function AC_PPARITH(dir: integer; a_in : std_ulogic_vector; ap_in : std_ulogic; b_in : std_ulogic_vector; bp_in : std_ulogic) return std_ulogic;

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** GLOBAL DONUT CONSTANT                      *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

  CONSTANT FIR_MSG_LEVEL   : severity_level := WARNING;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Interface Encoding
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- AH Command Interface Encoding
  --
  TYPE CMD_CODES_T IS (READ_CL_NA, READ_CL_S, READ_PE, READ_CL_M, READ_CL_LCK, READ_CL_RES, READ_PNA,
                       TOUCH_I, TOUCH_S, TOUCH_M,
                       WRITE_NA, WRITE_INJ, WRITE_MI, WRITE_MS, WRITE_UNLOCK, WRITE_C,
                       PUSH_I, PUSH_S,
                       EVICT_I, RESERVED,
                       LOCK, UNLOCK,
                       FLUSH, INTREQ, RESTART);
  TYPE ENCODING_CMD_CODES_ARRAY IS ARRAY(CMD_CODES_T) OF std_ulogic_vector(0 TO 12);
  CONSTANT ENCODE_CMD_CODES : ENCODING_CMD_CODES_ARRAY :=
    (READ_CL_NA    => '0' & x"A00",
     READ_CL_S     => '0' & x"A50",
     READ_PE       => '0' & x"A52",
     READ_CL_M     => '0' & x"A60",
     READ_CL_RES   => '0' & x"A67",
     READ_CL_LCK   => '0' & x"A6B",
     READ_PNA      => '0' & x"E00",
     TOUCH_I       => '0' & x"240",
     TOUCH_S       => '0' & x"250",
     TOUCH_M       => '0' & x"260",
     WRITE_NA      => '0' & x"D00",
     WRITE_INJ     => '0' & x"D10",
     WRITE_MI      => '0' & x"D60",
     WRITE_C       => '0' & x"D67",
     WRITE_UNLOCK  => '0' & x"D6B",
     WRITE_MS      => '0' & x"D70",
     PUSH_I        => '0' & x"140",
     PUSH_S        => '0' & x"150",
     EVICT_I       => '1' & x"140",
     RESERVED      => '1' & x"260",
     LOCK          => '0' & x"16B",
     UNLOCK        => '0' & x"17B",
     FLUSH         => '0' & x"100",
     INTREQ        => '0' & x"000",
     RESTART       => '0' & x"001");

  --
  -- HA Response Interface Encoding
  --
  TYPE RSP_CODES_T IS (DONE, AERROR, DERROR, NLOCK, NRES, FLUSHED, FAULT, FAILED, PAGED, CONTXT, ILLEGAL_RSP);
  TYPE CODING_RSP_ENCODES_ARRAY IS ARRAY (0 TO 255) OF RSP_CODES_T;
  CONSTANT ENCODE_RSP_CODES : CODING_RSP_ENCODES_ARRAY :=
    (     0 => DONE,
          1 => AERROR,
          3 => DERROR,
          4 => NLOCK,
          5 => NRES,
          6 => FLUSHED,
          7 => FAULT,
          8 => FAILED,
         10 => PAGED,
         11 => CONTXT,
     OTHERS => ILLEGAL_RSP);

  --
  -- HA JOB Control Interface Encoding
  --
  TYPE COM_CODES_T IS (START, RESET, LLCMD, TIMEBASE, ILLEGAL_COM);
  TYPE CODING_COM_ENCODES_ARRAY IS ARRAY (0 TO 255) OF COM_CODES_T;
  CONSTANT ENCODE_COM_CODES : CODING_COM_ENCODES_ARRAY :=
    (    66  => TIMEBASE,
         69  => LLCMD,
         128 => RESET,
         144 => START,
      OTHERS => ILLEGAL_COM
    );
  TYPE CODING_COM_PARITY_ARRAY IS ARRAY (COM_CODES_T) OF std_ulogic;
  CONSTANT COM_CODES_PARITY : CODING_COM_PARITY_ARRAY :=
    ( TIMEBASE => '1',
      LLCMD    => '0',
      RESET    => '0',
      START    => '1',
      OTHERS   => '0'
    );

  CONSTANT LLCMD_CMD_L        : integer := 63;
  CONSTANT LLCMD_CMD_R        : integer := 48;
  CONSTANT LLCMD_PE_HANDLE_L  : integer := 15;
  CONSTANT LLCMD_PE_HANDLE_R  : integer := 0;

  TYPE LLCMD_CODES_T IS (NO_CMD, TERMINATE_ELEMENT, REMOVE_ELEMENT, SUSPEND_ELEMENT, RESUME_ELEMENT, ADD_ELEMENT, UPDATE_ELEMENT, RESERVED_CMD);
  TYPE ENCODING_LLCMD_CODES_ARRAY IS ARRAY(LLCMD_CODES_T) OF std_ulogic_vector(15 DOWNTO 0);
  CONSTANT LLCMD_CODES : ENCODING_LLCMD_CODES_ARRAY :=
    ( NO_CMD            => x"0000",
      TERMINATE_ELEMENT => x"0001",
      REMOVE_ELEMENT    => x"0002",
      SUSPEND_ELEMENT   => x"0003",
      RESUME_ELEMENT    => x"0004",
      ADD_ELEMENT       => x"0005",
      UPDATE_ELEMENT    => x"0006",
      RESERVED_CMD      => x"FFFF"
    );
  TYPE CODING_LLCMD_CODES_ARRAY IS ARRAY(0 TO 7) OF LLCMD_CODES_T;
  CONSTANT CODING_LLCMD : CODING_LLCMD_CODES_ARRAY :=
    (      0 => NO_CMD,
           1 => TERMINATE_ELEMENT,
           2 => REMOVE_ELEMENT,
           3 => SUSPEND_ELEMENT,
           4 => RESUME_ELEMENT,
           5 => ADD_ELEMENT,
           6 => UPDATE_ELEMENT,
           7 => RESERVED_CMD
    );

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- MMIO Registers
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------

  -- PSL host address space (host addresses are 4B word adresses - i.e. you need to add lower two bit to obtain the complete byte address)
--  CONSTANT MASTER_BOUNDARY            : integer := 15;
  CONSTANT MASTER_ACTION_ACCESS_BIT   : integer := 14;  -- Action space for master access starts at 0x10000 (16 x 4KB)
  CONSTANT MASTER_ACTION_ID_L         : integer := 13;  -- Action ID is encoded in bits 15:12 of the real address
  CONSTANT MASTER_ACTION_ID_R         : integer := 10;  -- Action ID is encoded in bits 15:12 of the real address  
  CONSTANT NVME_SPACE_START_BIT       : integer := 15;  -- NVME space starts at address 0x20000
  CONSTANT SLAVE_SPACE_BIT            : integer := 23;  -- Slave (context) space starts at 0x2000000
  CONSTANT PSL_HOST_ADDR_MAXBIT       : integer := 23;
  CONSTANT PSL_HOST_CTX_ID_L          : integer := 22;
  CONSTANT PSL_HOST_CTX_ID_R          : integer := 14;
  CONSTANT SLAVE_ACTION_OFFSET_L      : integer := 13;
  CONSTANT SLAVE_ACTION_OFFSET_R      : integer := 10;
  CONSTANT SLAVE_ACTION_OFFSET_VAL    : std_ulogic_vector(13 DOWNTO 10) := "1111"; -- only bits 13 downto 10 of the PSL address are checked for action ACCESS

  -- Register base address (bits 13 downto 5 of the address)
  CONSTANT SNAP_REG_BASE              : integer := 16#000#;  -- 0x0000
  CONSTANT SNAP_EXT_REG_BASE          : integer := 16#001#;  -- 0x0080
  CONSTANT ACTION_TYPE_REG_BASE       : integer := 16#002#;  -- 0x0100
  CONSTANT ACTION_COUNTER_REG_BASE    : integer := 16#003#;  -- 0x0180
  CONSTANT CONTEXT_REG_BASE           : integer := 16#020#;  -- 0x1000
  CONSTANT DEBUG_REG_BASE             : integer := 16#1A0#;  -- 0xD000 TODO: remove!!
  CONSTANT FIR_REG_BASE               : integer := 16#1C0#;  -- 0xE000


  -- Register offset (bits 4 downto 1 of the address - note: bit 0 of addr is always '0')
  -- SNAP registers
  CONSTANT IMP_VERSION_REG            : integer := 16#0#;
  CONSTANT BUILD_DATE_REG             : integer := 16#1#;
  CONSTANT SNAP_CMD_REG               : integer := 16#2#;
  CONSTANT SNAP_STATUS_REG            : integer := 16#3#;
  CONSTANT MAX_SNAP_REG               : integer := 16#3#;  -- maximum index for snap register array
  -- SNAP extended registers
  CONSTANT SNAP_FRT_REG               : integer := 16#0#;
  CONSTANT SNAP_LOCK_REG              : integer := 16#4#;
  CONSTANT SNAP_CTX_ID_REG            : integer := 16#4#;

  -- ACTION_TYPE and ACTION_COUNTER registers
  CONSTANT MAX_ACTION_REG             : integer := 16#F#;

  -- Context registers
  CONSTANT CONTEXT_CONFIG_REG         : integer := 16#0#;
  CONSTANT CONTEXT_STATUS_REG         : integer := 16#1#;
  CONSTANT CONTEXT_COMMAND_REG        : integer := 16#2#;


  -- FIR registers
--  CONSTANT FIRREG_CTRL_MGR            : integer := 16#0#;
--  CONSTANT FIRREG_JOB_MGR             : integer := 16#1#;
--  CONSTANT FIRREG_MMIO                : integer := 16#2#;
--  CONSTANT FIRREG_DMA                 : integer := 16#3#;
--  CONSTANT MAX_FIR_REG                : integer := 16#3#;

  -- Specific bits of selected registers
  CONSTANT SNAP_STAT_EXPLORATION_DONE : integer :=  8;     -- SNAP_STATUS_REG
  CONSTANT SNAP_STAT_MAX_SAT_L        : integer :=  7;     -- SNAP_STATUS_REG
  CONSTANT SNAP_STAT_MAX_SAT_R        : integer :=  4;     -- SNAP_STATUS_REG
  CONSTANT SNAP_STAT_MAX_ACTION_ID_L  : integer :=  3;     -- SNAP_STATUS_REG
  CONSTANT SNAP_STAT_MAX_ACTION_ID_R  : integer :=  0;     -- SNAP_STATUS_REG
  CONSTANT SNAP_CMD_MAX_SAT_L         : integer := 51;     -- SNAP_STATUS_REG
  CONSTANT SNAP_CMD_MAX_SAT_R         : integer := 48;     -- SNAP_STATUS_REG
  CONSTANT SNAP_LOCK_INT              : integer :=  0;     -- SNAP_LOCK_REG
  CONSTANT SNAP_CTX_MASTER_BIT        : integer := 63;     -- SNAP_CTX_ID_REG
  CONSTANT SNAP_CTX_ID_L              : integer :=  8;     -- SNAP_CTX_ID_REG
  CONSTANT SNAP_CTX_ID_R              : integer :=  0;     -- SNAP_CTX_ID_REG

  CONSTANT CTX_CFG_SIZE_INT           : integer := 37;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_FIRST_SEQNO_L      : integer := 63;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_FIRST_SEQNO_R      : integer := 48;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_FIRST_JQIDX_L      : integer := 31;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_FIRST_JQIDX_R      : integer := 24;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_MAX_JQIDX_L        : integer := 23;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_MAX_JQIDX_R        : integer := 16;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_SAT_L              : integer := 15;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_SAT_R              : integer := 12;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_DIRECT_MODE        : integer :=  0;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_FIRST_SEQNO_INT_L  : integer := 36;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_FIRST_SEQNO_INT_R  : integer := 21;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_FIRST_JQIDX_INT_L  : integer := 20;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_FIRST_JQIDX_INT_R  : integer := 13;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_MAX_JQIDX_INT_L    : integer := 12;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_MAX_JQIDX_INT_R    : integer :=  5;     -- CONTEXT_CONFIG_REG
  CONSTANT CTX_CFG_SAT_INT_L          : integer :=  4;     -- CONTEXT_CONFIG_REG and CONTEXT_STATUS_REG
  CONSTANT CTX_CFG_SAT_INT_R          : integer :=  1;     -- CONTEXT_CONFIG_REG and CONTEXT_STATUS_REG
  CONSTANT CTX_CFG_DIRECT_MODE_INT    : integer :=  0;     -- CONTEXT_CONFIG_REG

  CONSTANT CTX_SEQNO_SIZE_INT         : integer := 40;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_CURRENT_L        : integer := 63;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_CURRENT_R        : integer := 48;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_LAST_L           : integer := 47;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_LAST_R           : integer := 32;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_JQIDX_L          : integer := 31;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_JQIDX_R          : integer := 24;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_CURRENT_INT_L    : integer := 39;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_CURRENT_INT_R    : integer := 24;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_LAST_INT_L       : integer := 23;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_LAST_INT_R       : integer :=  8;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_JQIDX_INT_L      : integer :=  7;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_SEQNO_JQIDX_INT_R      : integer :=  0;     -- CONTEXT_STATUS_REG

  CONSTANT CTX_STAT_SIZE_INT          : integer :=  8;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_SAT_L             : integer := 15;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_SAT_R             : integer := 12;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_SAT_VALID         : integer :=  7;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_ACTION_ID_L       : integer := 11;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_ACTION_ID_R       : integer :=  8;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_ACTION_VALID      : integer :=  6;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_JOB_ACTIVE        : integer :=  1;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_CTX_ACTIVE        : integer :=  0;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_ACTION_ID_INT_L   : integer :=  7;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_ACTION_ID_INT_R   : integer :=  4;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_SAT_VALID_INT     : integer :=  3;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_ACTION_VALID_INT  : integer :=  2;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_JOB_ACTIVE_INT    : integer :=  1;     -- CONTEXT_STATUS_REG
  CONSTANT CTX_STAT_CTX_ACTIVE_INT    : integer :=  0;     -- CONTEXT_STATUS_REG

  CONSTANT CTX_CMD_SIZE_INT           : integer := 20;     -- CONTEXT_COMMAND_REG
  CONSTANT CTX_CMD_ARG_L              : integer := 63;     -- CONTEXT_COMMAND_REG
  CONSTANT CTX_CMD_ARG_R              : integer := 48;     -- CONTEXT_COMMAND_REG
  CONSTANT CTX_CMD_CODE_L             : integer :=  3;     -- CONTEXT_COMMAND_REG
  CONSTANT CTX_CMD_CODE_R             : integer :=  0;     -- CONTEXT_COMMAND_REG
  CONSTANT CTX_CMD_ARG_INT_L          : integer := 19;     -- CONTEXT_COMMAND_REG
  CONSTANT CTX_CMD_ARG_INT_R          : integer :=  4;     -- CONTEXT_COMMAND_REG
  CONSTANT CTX_CMD_CODE_INT_L         : integer :=  3;     -- CONTEXT_COMMAND_REG
  CONSTANT CTX_CMD_CODE_INT_R         : integer :=  0;     -- CONTEXT_COMMAND_REG

  CONSTANT ATR_SAT_L                  : integer := 35;     -- ACTION_TYPE_REG
  CONSTANT ATR_SAT_R                  : integer := 32;     -- ACTION_TYPE_REG

  CONSTANT NFE_L                      : integer := 23;     -- DDCBQ_STAT_REG
  CONSTANT NFE_R                      : integer :=  8;     -- DDCBQ_STAT_REG
  CONSTANT NFE_CFG_ACTIVE             : integer := 15;     -- DDCBQ_STAT_REG
  CONSTANT NFE_ILLEGAL_CMD            : integer := 14;     -- DDCBQ_STAT_REG
  CONSTANT NFE_CFG_WR_ACCESS          : integer := 13;     -- DDCBQ_STAT_REG
  CONSTANT NFE_INV_WR_ACCESS          : integer := 12;     -- DDCBQ_STAT_REG
  CONSTANT NFE_INV_WR_ADDRESS         : integer := 11;     -- DDCBQ_STAT_REG
  CONSTANT NFE_MMIO_BAD_WR_AL         : integer := 10;     -- DDCBQ_STAT_REG
  CONSTANT NFE_INV_RD_ADDRESS         : integer :=  9;     -- DDCBQ_STAT_REG
  CONSTANT NFE_MMIO_BAD_RD_AL         : integer :=  8;     -- DDCBQ_STAT_REG
--  CONSTANT MASTER_ACCESS_BIT          : integer := 63;     -- DDCBQ_CONTEXT_ID_REG
--  CONSTANT CURRENT_CONTEXT_ID_L       : integer := 31;     -- DDCBQ_CONTEXT_ID_REG
--  CONSTANT CURRENT_CONTEXT_ID_R       : integer := 16;     -- DDCBQ_CONTEXT_ID_REG
--  CONSTANT MY_CONTEXT_ID_L            : integer := 15;     -- DDCBQ_CONTEXT_ID_REG
--  CONSTANT MY_CONTEXT_ID_R            : integer :=  0;     -- DDCBQ_CONTEXT_ID_REG

  -- FIR bits
  CONSTANT CTRLMGR_EA_PARITY_ERR      : integer :=  5;     -- CTRL_MGR_FIR
  CONSTANT CTRLMGR_COM_PARITY_ERR     : integer :=  4;     -- CTRL_MGR_FIR
  CONSTANT CTRLMGR_CTRL_FSM_ERR       : integer :=  1;     -- CTRL_MGR_FIR

  CONSTANT MMIO_DDCBQ_RAM_RD_ERR_L    : integer :=  9;
  CONSTANT MMIO_DDCBQ_RAM_RD_ERR_R    : integer :=  2;
  CONSTANT MMIO_DDCBQ_WT_RD_ERR       : integer :=  9;     -- MMIO_FIR
  CONSTANT MMIO_DDCBQ_DMAE_RD_ERR     : integer :=  8;     -- MMIO_FIR
  CONSTANT MMIO_DDCBQ_SEQL_RD_ERR     : integer :=  7;     -- MMIO_FIR
  CONSTANT MMIO_DDCBQ_SEQI_RD_ERR     : integer :=  6;     -- MMIO_FIR
  CONSTANT MMIO_DDCBQ_NFE_RD_ERR      : integer :=  5;     -- MMIO_FIR
  CONSTANT MMIO_DDCBQ_ST_RD_ERR       : integer :=  4;     -- MMIO_FIR
  CONSTANT MMIO_DDCBQ_CFG_RD_ERR      : integer :=  3;     -- MMIO_FIR
  CONSTANT MMIO_DDCBQ_SP_RD_ERR       : integer :=  2;     -- MMIO_FIR
  CONSTANT MMIO_ADDR_PARITY_ERR       : integer :=  1;     -- MMIO_FIR
  CONSTANT MMIO_DATA_PARITY_ERR       : integer :=  0;     -- MMIO_FIR

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Context Control
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- CONSTANT
  CONSTANT NUM_OF_CONTEXTS                 : integer := 512;      -- total number of supported contexts
  CONSTANT CONTEXT_BITS                    : integer :=   9;      -- number of bits required to represent the supported contexts as integer
  CONSTANT SEQNO_BITS                      : integer :=  16;      -- number of bits required to represent a valid sequence number
  CONSTANT JQIDX_BITS                      : integer :=   8;      -- number of bits required to represent a valid job queue index

--  CONSTANT ACTIVE_CONTEXTS_REGIONS_NUM     : integer :=  16;      -- number of active context regions
--  CONSTANT ACTIVE_CONTEXTS_REGION_BITS     : integer :=   5;      -- number of bits required to represent active context within the region as integer
--  CONSTANT ACTIVE_CONTEXTS_REGION_SIZE     : integer :=  2**ACTIVE_CONTEXTS_REGION_BITS; -- size in bits of each active context region
--  CONSTANT ATTACHED_CONTEXTS_REGISTERS_NUM : integer :=  16;      -- number of registers required to represent the attached processes
--  CONSTANT ATTACHED_CONTEXTS_REGISTER_BITS : integer :=   5;      -- number of bits required to represent the index of an attached process within an attached process register
--  CONSTANT ATTACHED_CONTEXTS_REGISTER_SIZE : integer :=  2**ATTACHED_CONTEXTS_REGISTER_BITS; -- size in bits of each atttached processes register

--  CONSTANT CONTEXT_TIME_SLICE_BITS : integer := 64;

  --
  -- TYPE
--  TYPE ACTIVE_CONTEXTS_ARRAY_T   IS ARRAY (natural RANGE <>) OF std_ulogic_vector(ACTIVE_CONTEXTS_REGION_SIZE-1 DOWNTO 0);
--  TYPE ATTACHED_CONTEXTS_ARRAY_T IS ARRAY (natural RANGE <>) OF std_ulogic_vector(ATTACHED_CONTEXTS_REGISTER_SIZE-1 DOWNTO 0);

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- Context Commands
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- CONSTANT
  CONSTANT CTX_NOP            : std_ulogic_vector(3 DOWNTO 0) := x"0";  -- CONTEXT_COMMAND_REG
  CONSTANT CTX_START          : std_ulogic_vector(3 DOWNTO 0) := x"1";  -- CONTEXT_COMMAND_REG
  CONSTANT CTX_STOP           : std_ulogic_vector(3 DOWNTO 0) := x"2";  -- CONTEXT_COMMAND_REG
  CONSTANT CTX_ABORT          : std_ulogic_vector(3 DOWNTO 0) := x"4";  -- CONTEXT_COMMAND_REG

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- SNAP DONUT Commands
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- CONSTANT
  CONSTANT SNAP_CMD_BITS_L      : integer := 4;                                                          -- SNAP_CMD_REG
  CONSTANT SNAP_CMD_BITS_R      : integer := 0;                                                          -- SNAP_CMD_REG
  CONSTANT SNAP_NOP             : std_ulogic_vector(SNAP_CMD_BITS_L DOWNTO SNAP_CMD_BITS_R) := "00000";  -- SNAP_CMD_REG
  CONSTANT SNAP_STOP            : std_ulogic_vector(SNAP_CMD_BITS_L DOWNTO SNAP_CMD_BITS_R) := "00010";  -- SNAP_CMD_REG
  CONSTANT SNAP_ABORT           : std_ulogic_vector(SNAP_CMD_BITS_L DOWNTO SNAP_CMD_BITS_R) := "00100";  -- SNAP_CMD_REG
  CONSTANT SNAP_RESET           : std_ulogic_vector(SNAP_CMD_BITS_L DOWNTO SNAP_CMD_BITS_R) := "01000";  -- SNAP_CMD_REG
  CONSTANT EXPLORATION_DONE     : std_ulogic_vector(SNAP_CMD_BITS_L DOWNTO SNAP_CMD_BITS_R) := "10000";  -- SNAP_CMD_REG

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- AFU Descriptor
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  CONSTANT AFU_DESCRIPTOR_BASE  : integer := 16#000#;

  TYPE AFU_DES_T IS RECORD
    NUM_INTS_PER_PROCESS   : std_ulogic_vector(15 DOWNTO 0);
    NUM_OF_PROCESSES       : std_ulogic_vector(15 DOWNTO 0);
    NUM_OF_AFU_CRS         : std_ulogic_vector(15 DOWNTO 0);
    REG_PROG_MODEL         : std_ulogic_vector(15 DOWNTO 0);
    AFU_CR_LEN             : std_ulogic_vector(55 DOWNTO 0);
    AFU_CR_OFFSET          : std_ulogic_vector(63 DOWNTO 0);
    PERPROCESSPSA_CONTROL  : std_ulogic_vector( 7 DOWNTO 0);
    PERPROCESSPSA_LENGTH   : std_ulogic_vector(55 DOWNTO 0);
    PERPROCESSPSA_OFFSET   : std_ulogic_vector(63 DOWNTO 0);
    AFU_EB_LEN             : std_ulogic_vector(55 DOWNTO 0);
    AFU_EB_OFFSET          : std_ulogic_vector(63 DOWNTO 0);
  END RECORD;

  CONSTANT AFU_DES_INI : AFU_DES_T :=             -- see Coherent Accelerator Interface Architecture (CAIA) spec for definition of AFU Descriptor
    (NUM_INTS_PER_PROCESS  => x"0002",                  -- x'00'  0:15 SNAP requires two interrupts per context (need more?)
     NUM_OF_PROCESSES      => x"0200",                  -- x'00' 16:31 SNAP supports 512 contexts
     NUM_OF_AFU_CRS        => x"0001",                  -- x'00' 32:47 SNAP provides one config record
     REG_PROG_MODEL        => x"0004",                  -- x'00' 48:63 SNAP requires directed mode programming model
     AFU_CR_LEN            =>   x"00_0000_0000_0001",   -- x'20'  8:63 SNAP provides one 256 bytes config record
     AFU_CR_OFFSET         => x"0000_0000_0000_0100",   -- x'28'  0:63 The config record starts at address 0x100 of the config space (directly behind the descripter)
     PERPROCESSPSA_CONTROL => x"03",                    -- x'30'  0: 7 Per process PSA (MMIO space for each context) required
     PERPROCESSPSA_LENGTH  =>   x"00_0000_0000_0010",   -- x'30'  8:63 Each per process PSA is 16 * 4KB = 64KB in size
     PERPROCESSPSA_OFFSET  => x"0000_0000_0200_0000",   -- x'38'  0:63 Per process PSA starts at 0x2000000
     AFU_EB_LEN            =>   x"00_0000_0000_0001",   -- x'40'  8:63 A 4 KB error buffer is supported (not yet used)
     AFU_EB_OFFSET         => x"0000_0000_0000_1000"    -- x'48'  0:63 The error buffer starts at address 0x1000 of the config space
    );

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- AFU Config Space
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  CONSTANT AFU_CFG_SPACE0_BASE  : integer := 16#002#;
  CONSTANT AFU_CFG_SPACE1_BASE  : integer := 16#003#;
  CONSTANT AFU_CFG_SPACE_SIZE   : integer := 2;

  TYPE AFU_CFG_T IS RECORD
    AFU_DEVICE_ID   : std_ulogic_vector(31 DOWNTO 16);
    AFU_VENDOR_ID   : std_ulogic_vector(15 DOWNTO  0);
    AFU_CLASS_CODE  : std_ulogic_vector(31 DOWNTO  8);
    AFU_REVISION_ID : std_ulogic_vector( 7 DOWNTO  0);
  END RECORD;

  CONSTANT AFU_CFG_INI : AFU_CFG_T :=
    (AFU_DEVICE_ID   => x"FECA",                  -- TODO: device id for CAPI accelerated adapter
     AFU_VENDOR_ID   => x"1410",                  -- IBM
     AFU_CLASS_CODE  => x"000012",                -- accelerator
     AFU_REVISION_ID => x"01"                     -- TODO: value
    );

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- ACTION Control
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- CONSTANT
  CONSTANT ACTION_TYPE_BITS                : integer :=   4;      -- number of bits required to represent the action types
  CONSTANT NUM_OF_ACTION_TYPES             : integer :=  16;      -- maximum number of supported action types
  CONSTANT ACTION_BITS                     : integer :=   4;      -- number of bits required to represent the action IDs
  CONSTANT NUM_OF_ACTIONS                  : integer :=  16;      -- maximum number of supported actions

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** GLOBAL TYPES                               *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  -- ARRAY TYPES
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --
  -- TYPE
  TYPE ACTION_TYPE_ARRAY IS ARRAY (integer RANGE <>) OF std_ulogic_vector(ACTION_TYPE_BITS-1 DOWNTO 0);
  TYPE ACTION_ID_ARRAY IS ARRAY (integer RANGE <>) OF std_ulogic_vector(ACTION_BITS-1 DOWNTO 0);
  TYPE ACTION_MASK_ARRAY IS ARRAY (integer RANGE <>) OF std_ulogic_vector(NUM_OF_ACTIONS-1 DOWNTO 0);
  TYPE CONTEXT_ID_ARRAY IS ARRAY (integer RANGE <>) OF std_ulogic_vector(CONTEXT_BITS-1 DOWNTO 0);
  TYPE SEQNO_ARRAY IS ARRAY (integer RANGE <>) OF std_ulogic_vector(SEQNO_BITS-1 DOWNTO 0);
  TYPE JQIDX_ARRAY IS ARRAY (integer RANGE <>) OF std_ulogic_vector(JQIDX_BITS-1 DOWNTO 0);

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** AFU EXTERNAL INTERFACE TYPES               *****
-- ******************************************************
--
--  *_c : Command  Interface
--  *_b : Buffer   Interface
--  *_r : Response Interface
--  *_mm: MMIO     Interface
--  *_j : Control  Interface
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  Command Interface
  --
  --  ha_c (from PSL)
  --  ah_c (to   PSL)
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    --  ha_c (from PSL)
    --
    TYPE HA_C_T IS RECORD
      room        : std_ulogic_vector(7 DOWNTO 0);        -- Command room
    END RECORD HA_C_T;

    --
    --  ah_c (to   PSL)
    --
    TYPE AH_C_T IS RECORD
      valid       : std_ulogic;                           -- Command valid
      tag         : std_ulogic_vector(7  DOWNTO 0);       -- Command tag
      tagpar      : std_ulogic;                           -- Command tag parity
      com         : CMD_CODES_T;                          -- Command code
      compar      : std_ulogic;                           -- Command code parity
      abt         : std_ulogic_vector(2 DOWNTO 0);        -- Command ABT
      ea          : std_ulogic_vector(63 DOWNTO 0);       -- Command address
      eapar       : std_ulogic;                           -- Command address parity
      ch          : std_ulogic_vector(15 DOWNTO 0);       -- Command context handle
      size        : std_ulogic_vector(11 DOWNTO 0);       -- Command size
    END RECORD AH_C_T;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Buffer Interface
  --
  --  ha_b (from PSL)
  --  ah_b (to   PSL)
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    --  ha_b (from PSL)
    --
    TYPE HA_B_T IS RECORD
      rvalid      : std_ulogic;                           -- Buffer Read valid
      rtag        : std_ulogic_vector(7 DOWNTO 0);        -- Buffer Read tag
      rtagpar     : std_ulogic;                           -- Buffer Read tag parity
      rad         : std_ulogic_vector(5 DOWNTO 0);        -- Buffer Read address
      wvalid      : std_ulogic;                           -- Buffer Write valid
      wtag        : std_ulogic_vector(7 DOWNTO 0);        -- Buffer Write tag
      wtagpar     : std_ulogic;                           -- Buffer Write tag parity
      wad         : std_ulogic_vector(5   DOWNTO 0);      -- Buffer Write address
      wdata       : std_ulogic_vector(511 DOWNTO 0);      -- Buffer Write data
      wpar        : std_ulogic_vector(7   DOWNTO 0);      -- Buffer Write parity
    END RECORD HA_B_T;

    --
    --  ah_b (to   PSL)
    --
    TYPE AH_B_T IS RECORD
      rlat        : std_ulogic_vector(3   DOWNTO 0);      -- Buffer Read latency
      rdata       : std_ulogic_vector(511 DOWNTO 0);      -- Buffer Read data
      rpar        : std_ulogic_vector(7   DOWNTO 0);      -- Buffer Read parity
    END RECORD AH_B_T;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Response Interface
  --
  --  ha_r (from PSL)
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    --  ha_r (from PSL)
    --
    TYPE HA_R_T IS RECORD
      valid       : std_ulogic;                           -- Response valid
      tag         : std_ulogic_vector(7  DOWNTO 0);       -- Response tag
      tagpar      : std_ulogic;                           -- Response tag parity
      response    : RSP_CODES_T;                          -- Response
      credits     : std_ulogic_vector(8  DOWNTO 0);       -- Response credits
      cachestate  : std_ulogic_vector(1  DOWNTO 0);       -- Response cache state
      cachepos    : std_ulogic_vector(12 DOWNTO 0);       -- Response cache pos
    END RECORD HA_R_T;


  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  MMIO Interface
  --
  --  ha_mm (from PSL)
  --  ah_mm (to   PSL)
  --  mm_e  (internal to MMIO for error reporting)
  --  mm_i  (internal to MMIO for error injection)
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    --  ha_mm (from PSL)
    --
    TYPE HA_MM_T IS RECORD
      valid      : std_ulogic;                            -- A valid MMIO is present
      cfg        : std_ulogic;                            -- MMIO is AFU descriptor space access
      rnw        : std_ulogic;                            -- 1 = read  0 = write
      dw         : std_ulogic;                            -- 1 = doubleword  0 = word
      ad         : std_ulogic_vector(23 DOWNTO 0);        -- mmio address
      adpar      : std_ulogic;                            -- mmio address parity
      data       : std_ulogic_vector(63 DOWNTO 0);        -- Write data
      datapar    : std_ulogic;                            -- Write data parity
    END RECORD HA_MM_T;

    --
    --  ah_mm (to   PSL)
    --
    TYPE AH_MM_T IS RECORD
      ack        : std_ulogic;                            -- Write is complete or Read is valid
      data       : std_ulogic_vector(63 DOWNTO 0);        -- Read data
      datapar    : std_ulogic;                            -- Read data parity
    END RECORD AH_MM_T;


    --
    --  mm_e (internal to MMIO for error reporting)
    TYPE MM_E_T IS RECORD
      wr_data_parity_err     : std_ulogic;
      wr_addr_parity_err     : std_ulogic;
      rd_data_parity_err     : std_ulogic_vector(MMIO_DDCBQ_RAM_RD_ERR_L DOWNTO MMIO_DDCBQ_RAM_RD_ERR_R);
    END RECORD;

    -- mm_i (internal to MMIO for error injection)
    TYPE MM_I_T IS RECORD
      inject_read_rsp_parity_error : std_ulogic;
      inject_write_parity_error    : std_ulogic;
    END RECORD;

  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
  --  Control Interface
  --
  --  ha_j (from PSL)
  --  ah_j (to   PSL)
  ------------------------------------------------------------------------------
  ------------------------------------------------------------------------------
    --
    -- ha_j (from PSL)
    --
    TYPE HA_J_T IS RECORD
      valid            : std_ulogic;                      -- Job valid
      com              : COM_CODES_T;                     -- Job command
      compar           : std_ulogic;                      -- Job command parity
      ea               : std_ulogic_vector(63 DOWNTO 0);  -- Job address / LLCMD information
      eapar            : std_ulogic;                      -- Job address parity
    END RECORD HA_J_T;

    --
    -- ah_j (to   PSL)
    --
    TYPE AH_J_T IS RECORD
      running          : std_ulogic;                      -- Job running
      done             : std_ulogic;                      -- Job done
      cack             : std_ulogic;                      -- Acknowledge completion of LLCMD
      error            : std_ulogic_vector(63 DOWNTO 0);  -- AFU error
      yield            : std_ulogic;                      -- Job yield
    END RECORD AH_J_T;


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** AFU INTERNAL INTERFACE TYPES               *****
-- ******************************************************
--
--  dj_c : dma         -> job_mgr     : Command Interface
--  dj_d : dma         -> job_mgr     : Data Interface
--  db_c : dma         -> data_bridge : Command Interface
--  db_d : dma         -> data_bridge : Data Interface
--  dmm_e: dma         -> mmio        : Error Interface
--  ds_c : dma         -> AXI slave   : Control Interface
--  ds_d : dma         -> AXI slave   : Data Interface
--
--  cmm_e: ctrl_mgr    -> mmio        : Error Interface
--
--  jmm_c: job_manager -> mmio        : Control Interface
--  jmm_d: job_manager -> mmio        : Data Interface
--  jx_c : job_manager -> AXI master  : Control Interface
--
--  mmc_c: mmio        -> ctrl_mgr    : Control Interface
--  mmc_e: mmio        -> ctrl_mgr    : Error Interface
--  mmd_a: mmio        -> dma         : Aggravater Interface
--  mmd_i: mmio        -> dma         : Error Inject
--  mmj_c: mmio        -> job_manager : Control Interface
--  mmj_d: mmio        -> job_manager : Data Interface
--  mmx_d: mmio        -> AXI master  : Data Interface
--  mmx_c: mmio        -> AXI master  : Control Interface
--
--  nx_d : NVMe        -> AXI master  : Data Interface
--
--  sd_c : AXI slave   -> dma         : Control Interface
--  sd_d : AXI slave   -> dma         : Data Interface
--
--  xmm_d: AXI master  -> mmio        : Data Interface
--  xmm_c: AXI master  -> mmio        : Control Interface
--  xj_c : AXI master  -> job_mgr     : Control Interface
--  xn_d : AXI master  -> NVMe        : Data Interface
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  DMA Interface
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    -- ds_c
    --
    TYPE DS_C_T IS RECORD
      wr_req_ack        : std_ulogic;                                           --
      rd_req_ack        : std_ulogic;                                           --
      wr_id_valid       : std_ulogic;                                           --
      wr_id             : std_ulogic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);     --
    END RECORD DS_C_T;

    --
    -- ds_d
    --
    TYPE DS_D_T IS RECORD
      rd_data_strobe    : std_ulogic;                                           --valid
      rd_last           : std_ulogic;                                           --
      rd_data           : std_ulogic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);   -- data
      rd_id             : std_ulogic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);     --
    END RECORD DS_D_T;

    --
    -- dmm_e
    --
    TYPE DMM_E_T IS RECORD
      ah_c_fsm_err        : std_ulogic;
      read_ctrl_fsm_err   : std_ulogic;
      read_ctrl_q_err     : std_ulogic;
      write_ctrl_fsm_err  : std_ulogic;
      write_ctrl_q_err    : std_ulogic;
      ha_r_tag_err        : std_ulogic;
      ha_r_code_err       : std_ulogic;
      ha_b_rtag_err       : std_ulogic;
      ha_b_wtag_err       : std_ulogic;
      ha_b_wdata_err      : std_ulogic;
      aln_read_fsm_err    : std_ulogic;
      aln_write_fsm_err   : std_ulogic;
      sd_p_err            : std_ulogic;
      write_data_p_err    : std_ulogic;
      com_rtag_err        : std_ulogic;
      clt_rtag_err        : std_ulogic;
      rsp_rtag_err        : std_ulogic;
      buf_rtag_err        : std_ulogic;
      raddr_err           : std_ulogic;
      com_wtag_err        : std_ulogic;
      clt_wtag_err        : std_ulogic;
      rsp_wtag_err        : std_ulogic;
      buf_wtag_err        : std_ulogic;
      waddr_err           : std_ulogic;
    END RECORD DMM_E_T;


  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  CTRL Interface
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    -- cmm_e
    --
    TYPE CMM_E_T IS RECORD
      ctrl_fsm_err     : std_ulogic;
      com_parity_err   : std_ulogic;
      ea_parity_err    : std_ulogic;
    END RECORD;


  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  Job Manager Interface
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    -- jmm_c
    --
    TYPE JMM_C_T IS RECORD
      context_id      : std_ulogic_vector(CONTEXT_BITS-1 DOWNTO 0);
      seqno_we        : std_ulogic;
      status_we       : std_ulogic;
    END RECORD;

    --
    -- jmm_d
    --
    TYPE JMM_D_T IS RECORD
      seqno              : std_ulogic_vector(CTX_SEQNO_CURRENT_L DOWNTO CTX_SEQNO_CURRENT_R);
      jqidx              : std_ulogic_vector(CTX_SEQNO_JQIDX_L DOWNTO CTX_SEQNO_JQIDX_R);
      action_id          : std_ulogic_vector(CTX_STAT_ACTION_ID_L DOWNTO CTX_STAT_ACTION_ID_R);
      action_active      : std_ulogic_vector(NUM_OF_ACTIONS-1 DOWNTO 0);
      attached_to_action : std_ulogic;
      context_active     : std_ulogic;
    END RECORD;

    --
    -- jx_c
    --
    TYPE JX_C_T IS RECORD
      check_for_idle     : std_ulogic_vector(ACTION_BITS-1 downto 0);
    END RECORD JX_C_T;


  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  MMIO Interface
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    -- mmc_c
    --
    TYPE MMC_C_T IS RECORD
      reset_done : std_ulogic;
    END RECORD MMC_C_T;

    --
    -- mmc_e
    --
    TYPE MMC_E_T IS RECORD
      error : std_ulogic_vector(63 DOWNTO 0);
    END RECORD MMC_E_T;

    --
    --
    -- mmd_a
    TYPE MMD_A_T IS RECORD
      thr_read_fsm        : std_ulogic;
      thr_write_fsm       : std_ulogic;
      thr_cmd_fsm         : std_ulogic;
    END RECORD MMD_A_T;

    --
    -- mmd_i
    --
    TYPE MMD_I_T IS RECORD
      inject_dma_write_error    : std_ulogic;
      inject_dma_read_error     : std_ulogic;
      inject_ah_c_compar_error  : std_ulogic;
      inject_ah_c_eapar_error   : std_ulogic;
      inject_ah_b_rpar_error    : std_ulogic;
      inject_ah_c_tagpar_error  : std_ulogic;
    END RECORD;

    --
    -- mmj_c
    --
    TYPE MMJ_C_T IS RECORD
      ctx_fifo_we               : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
      ctx_stop                  : std_ulogic_vector(NUM_OF_ACTION_TYPES-1 DOWNTO 0);
      exploration_done          : std_ulogic;
      max_sat                   : integer RANGE 0 TO NUM_OF_ACTION_TYPES-1;
      last_seqno                : std_ulogic;
    END RECORD;

    --
    -- mmj_d
    --
    TYPE MMJ_D_T IS RECORD
      context_id                : std_ulogic_vector(CONTEXT_BITS-1 DOWNTO 0);
      action_id                 : std_ulogic_vector(CTX_STAT_ACTION_ID_L DOWNTO CTX_STAT_ACTION_ID_R);
      sat                       : ACTION_TYPE_ARRAY(NUM_OF_ACTIONS-1 DOWNTO 0);
      current_seqno             : std_ulogic_vector(CTX_SEQNO_CURRENT_L DOWNTO CTX_SEQNO_CURRENT_R);
      current_jqidx             : std_ulogic_vector(CTX_SEQNO_JQIDX_L DOWNTO CTX_SEQNO_JQIDX_R);
      job_queue_mode            : std_ulogic;
    END RECORD;

    --
    -- mmx_d
    --
    TYPE MMX_D_T IS RECORD
      addr                : std_ulogic_vector(31 DOWNTO 0);
      data                : std_ulogic_vector(31 DOWNTO 0);
      wr_strobe           : std_ulogic;
      rd_strobe           : std_ulogic;
    END RECORD MMX_D_T;


  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  AXI SLAVE Interface
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    -- sd_c
    --
    TYPE SD_C_T IS RECORD
      wr_req            : std_ulogic;                                           --wvalid
      wr_addr           : std_ulogic_vector(63 downto 0);                       --waddr
      wr_len            : std_ulogic_vector( 7 downto 0);                       --wlen
      wr_id             : std_ulogic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);     --action ID
      rd_req            : std_ulogic;                                           --rvalid
      rd_addr           : std_ulogic_vector(63 downto 0);                       --raddr
      rd_len            : std_ulogic_vector( 7 downto 0);                       --rlen
      rd_id             : std_ulogic_vector(C_S_AXI_ID_WIDTH - 1 downto 0);     --action ID
    END RECORD SD_C_T;

    --
    -- sd_d
    --
    TYPE SD_D_T IS RECORD
      wr_strobe         : std_ulogic_vector(C_S_AXI_DATA_WIDTH/8 - 1 downto 0); -- valid + byte_enable
      wr_last           : std_ulogic;                                           --
      wr_data           : std_ulogic_vector(C_S_AXI_DATA_WIDTH - 1 downto 0);   -- data
      rd_data_ack       : std_ulogic;                                           --
    END RECORD SD_D_T;


  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  AXI MASTER Interface
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    -- xmm_d
    --
    TYPE XMM_D_T IS RECORD
      data                : std_ulogic_vector(31 DOWNTO 0);
      ack                 : std_ulogic;
      error               : std_ulogic_vector( 1 DOWNTO 0);
    END RECORD XMM_D_T;

    --
    -- xj_c
    --
    TYPE XJ_C_T IS RECORD
      valid               : std_ulogic;
      action              : std_ulogic_vector(ACTION_BITS-1 downto 0);
    END RECORD XJ_C_T;

    --
    -- nx_d
    --
    TYPE NX_D_T IS RECORD
      M_AXI_AWREADY   : std_logic;
      M_AXI_WREADY    : std_logic;
      M_AXI_BRESP     : std_logic_vector(1 DOWNTO 0);
      M_AXI_BVALID    : std_logic;
      M_AXI_ARREADY   : std_logic;
      M_AXI_RDATA     : std_logic_vector(31 DOWNTO 0);
      M_AXI_RRESP     : std_logic_vector(1 DOWNTO 0);
      M_AXI_RVALID    : std_logic;
    END RECORD NX_D_T;

    --
    -- xn_d
    --
    TYPE XN_D_T IS RECORD
      M_AXI_AWADDR    : std_logic_vector(31 DOWNTO 0);
      M_AXI_AWPROT    : std_logic_vector(2 DOWNTO 0);
      M_AXI_AWVALID   : std_logic;
      M_AXI_WDATA     : std_logic_vector(31 DOWNTO 0);
      M_AXI_WSTRB     : std_logic_vector(3 DOWNTO 0);
      M_AXI_WVALID    : std_logic;
      M_AXI_BREADY    : std_logic;
      M_AXI_ARADDR    : std_logic_vector(31 DOWNTO 0);
      M_AXI_ARPROT    : std_logic_vector(2 DOWNTO 0);
      M_AXI_ARVALID   : std_logic;
      M_AXI_RREADY    : std_logic;
    END RECORD XN_D_T;

  
END donut_types;


PACKAGE BODY donut_types IS

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- ******************************************************
-- ***** AFU FUNCTIONS                              *****
-- ******************************************************
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  Verilog <-> VHDL Connector
  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    -- verilog to vhdl connector
    --
    FUNCTION v2vhdl_connector(CONSTANT data_in :std_ulogic_vector) RETURN std_ulogic_vector IS
      VARIABLE data_out_v : std_ulogic_vector(data_in'high DOWNTO data_in'low);
    BEGIN
      FOR  i IN data_in'low TO data_in'high  LOOP
        data_out_v(i) := data_in(data_in'high - i);
      END LOOP;

      RETURN data_out_v;
    END v2vhdl_connector;

    --
    -- vhdl to verilog connector
    --
    FUNCTION vhdl2v_connector(CONSTANT data_in :std_ulogic_vector) RETURN std_ulogic_vector IS
      VARIABLE data_out_v : std_ulogic_vector(data_in'low TO data_in'high);
    BEGIN
      FOR  i IN data_in'low TO data_in'high  LOOP
        data_out_v(i) := data_in(data_in'high - i);
      END LOOP;

      RETURN data_out_v;
    END vhdl2v_connector;


  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  Parity Generator
  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    --
    -- 4 bit odd parity out of 32 bit
    --
    FUNCTION gen_parity_odd_32( CONSTANT data : IN std_ulogic_vector ) RETURN std_ulogic_vector IS
      VARIABLE res : std_ulogic_vector(3 DOWNTO 0);
    BEGIN
      FOR i  IN 0 TO 3 LOOP
        res(i) := parity_gen_odd(data(data'low+7+i*8 DOWNTO data'low+i*8));
      END LOOP;  -- i
      return res;
    END gen_parity_odd_32;


    --
    -- 8 bit odd parity out of 64 bit
    --
    FUNCTION gen_parity_odd_64( CONSTANT data : IN std_ulogic_vector ) RETURN std_ulogic_vector IS
      VARIABLE res : std_ulogic_vector(7 DOWNTO 0);
    BEGIN
      FOR i  IN 0 TO 7 LOOP
        res(i) := parity_gen_odd(data(data'low+7+i*8 DOWNTO data'low+i*8));
      END LOOP;  -- i
      return res;
    END gen_parity_odd_64;

    --
    -- 16 bit odd parity out of 128 bit
    --
    FUNCTION gen_parity_odd_128( CONSTANT data : IN std_ulogic_vector ) RETURN std_ulogic_vector IS
      VARIABLE res : std_ulogic_vector(15 DOWNTO 0);
    BEGIN
      FOR i  IN 0 TO 15 LOOP
        res(i) := parity_gen_odd(data(data'low+7+i*8 DOWNTO data'low+i*8));
      END LOOP;  -- i
      return res;
    END gen_parity_odd_128;

    -- Generate odd byte wide parity with pad to 8-bit boundary on the RIGHT
    -- w : byte width (normally 8)
    function AC_GENPARITY( data_in :std_ulogic_vector; w: natural) return std_ulogic_vector is
      variable data : std_ulogic_vector(0 to  ((data_in'length-1)/w+1)*w -1);
      variable z    : std_ulogic_vector(0 to  ( data_in'length-1)/w        );
    begin

      data := (others => '0');
      data(0 to data_in'length-1)  := data_in;  -- normalize to left'=0, and even multiple of w.
      for i in 0 to data'length/w -1 loop
        z(i) := xnor_reduce(data(w*i to w*(i+1)-1));
      end loop;
      return z;
    end AC_GENPARITY;

    function AC_GENPARITY(data_in : std_ulogic_vector) return std_ulogic_vector is
      variable z    : std_ulogic_vector(0 to (data_in'length-1)/8);
    begin
      z := AC_GENPARITY(data_in,8);
      return z;
    end AC_GENPARITY;


  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --  Parity Prediction
  ---------------------------------------------------------------------------
  ----------------------------------------------------------------------------
    function AC_PPARITH(dir: integer; a_in ,ap_in,b_in,bp_in : std_ulogic_vector; w: natural := 8) return std_ulogic_vector is
      -- odd parity predicting arithmetic (adder/subt)
      -- given addends with parity,  predicts what the parity of the sum will be
      -- result needs inverting if even parity is used.
      -- dir is 1 : add,  -1 : subtract.
      -- w is the parity byte size. (typically 8)
      constant add : std_ulogic_vector(7 downto 0) := "11101000";   -- majority function
      constant sub : std_ulogic_vector(7 downto 0) := "10001110";
      variable a,b,c : std_ulogic_vector(a_in'length -1 downto 0);
      variable sp,cp,z : std_ulogic_vector(ap_in'length-1 downto 0);
      variable y : std_ulogic_vector(2 downto 0);
    begin
      a := a_in;
      b := b_in;
      c(0) := '0';
      -- calc the carry
      for i in 1 to a'length-1 loop
        -- majority  function.  code for a 3input lut
        y := a(i-1) & b(i-1) & c(i-1);
        if dir=1 then c(i) := add(tconv(y));
        else c(i) := sub(tconv(y));
        end if;
      end loop;
      -- find the parity of the operands.
      sp := ap_in xor bp_in;
      -- find the parity of carry chain
      cp := ac_genparity(c,w);
      -- modulate
      z  := sp xor cp;
      return z;
    end function AC_PPARITH;


    function AC_PPARITH(dir:integer; a_in : std_ulogic_vector; ap_in : std_ulogic;
                                     b_in : std_ulogic_vector; bp_in : std_ulogic) return std_ulogic is
      variable z : std_ulogic_vector(0 to 0);
    begin
      z := ac_pparith(dir, a_in , (0 to 0 => ap_in), b_in, (0 to 0 => bp_in), a_in'length);
      return z(0);
    end function AC_PPARITH;

END donut_types;