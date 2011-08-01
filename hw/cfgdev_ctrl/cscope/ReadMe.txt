cfgdev_host_ila.cpj - проект для Analizator ChipScoupe.  Для версии с использование модуля CoreGen ILA


component dbgcs_cfg
  PORT (
    CONTROL : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CLK : IN STD_LOGIC;
    DATA : IN STD_LOGIC_VECTOR(113 downto 0);
    TRIG0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
end component;


m_dbgcs_cfg : dbgcs_cfg
port map
(
CONTROL => i_dbgcs_cfg,
CLK     => i_cfg_dbgcs.clk,
DATA    => i_cfg_dbgcs.data(113 downto 0),
TRIG0   => i_cfg_dbgcs.trig0(15 downto 0)
);

i_cfg_dbgcs.clk<=g_host_clk;

process(i_cfg_dbgcs.clk)
begin
if i_cfg_dbgcs.clk'event and i_cfg_dbgcs.clk='1' then
--//-------- TRIG: ------------------
i_cfg_dbgcs.trig0(3 downto 0)<=i_cfg_dadr(3 downto 0);
i_cfg_dbgcs.trig0(11 downto 4)<=i_cfg_radr(7 downto 0);
i_cfg_dbgcs.trig0(12)<=i_cfg_wr;
i_cfg_dbgcs.trig0(13)<=i_cfg_rd;
i_cfg_dbgcs.trig0(14)<=i_host_devcfg_rd;
i_cfg_dbgcs.trig0(15)<=i_hdd_done;


--//-------- VIEW: ------------------
i_cfg_dbgcs.data(3 downto 0)<=i_cfg_dadr(3 downto 0);
i_cfg_dbgcs.data(11 downto 4)<=i_cfg_radr(7 downto 0);
i_cfg_dbgcs.data(12)<=i_cfg_wr;
i_cfg_dbgcs.data(13)<=i_cfg_rd;
i_cfg_dbgcs.data(14)<=i_hdd_done;
i_cfg_dbgcs.data(15)<=i_cfg_radr_ld;
i_cfg_dbgcs.data(31 downto 16)<=i_cfg_txdata;
i_cfg_dbgcs.data(47 downto 32)<=i_cfg_rxdata;
i_cfg_dbgcs.data(48)<=i_host_devcfg_rd;
i_cfg_dbgcs.data(49)<=i_host_devcfg_wd;
i_cfg_dbgcs.data(81 downto 50)<=i_host_devcfg_rxdata(31 downto 0);
i_cfg_dbgcs.data(113 downto 82)<=i_host_devcfg_txdata(31 downto 0);
end if;
end process;