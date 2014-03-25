local bin = require "bin"
local comm = require "comm"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"
local nsedebug = require "nsedebug"

description = [[
Discovers and enumerates BACNet Devices collects device information based off standard requests. In some cases, 
devices may not strictly follow the specifications, or may comply with older versions of the 
specifications, and will result in a BACNET error response. Presence of this error positively 
identifies the device as a BACNet device, but no enumeration is possible. 

Note: Requests and responses are via UDP 47808, ensure scanner will receive UDP 47808 source 
and destination responses.

http://digitalbond.com

]]

---
-- @usage
-- nmap --script BACnet-discover-enumerate.nse -sU  -p 47808 <host>
--
-- @args aggressive - boolean value defines find all or just first sid
--
-- @output
--47808/udp open  BACNet -- Building Automation and Control Networks
--| bacnet-discover:
--|
--| Vendor ID: BACnet Stack at SourceForge (260)
--| Instance Number: 260001
--| Firmware: 0.8.2
--| Application Software: 1.0
--| Object Name: SimpleServer
--| Model Name: GNU
--| Description: server
--|_Location: USA

     

author = "Stephen Hilt && Michael Toecker (Digital Bond)"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"discovery", "intrusive"}


--
-- Function to define the portrule
--
--
--
function portrule(host, port)
	return port.number == 47808
end

--
-- Function to determine if a string starts with something
-- 
--
--
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end


--
--  Function to look up the Vendor Name based on Vendor ID
--		Returns "Unknown Vendor Number" if Vendor ID not recognized
--  Table data from http://www.bacnet.org/VendorID/BACnet%20Vendor%20IDs.htm
--  Fetched on 3/18/2014
--  

function vendor_lookup(vennum)
	local vendor_id = { 
		[0] = "ASHRAE",
		[1] = "NIST",
		[2] = "The Trane Company",
		[3] = "McQuay International",
		[4] = "PolarSoft",
		[5] = "Johnson Controls Inc.",
		[6] = "American Auto-Matrix",
		[7] = "Siemens Schweiz AG (Formerly: Landis & Staefa Division Europe)",
		[8] = "Delta Controls",
		[9] = "Siemens Schweiz AG",
		[10] = "Schneider Electric",
		[11] = "TAC",
		[12] = "Orion Analysis Corporation",
		[13] = "Teletrol Systems Inc.",
		[14] = "Cimetrics Technology",
		[15] = "Cornell University",
		[16] = "United Technologies Carrier",
		[17] = "Honeywell Inc.",
		[18] = "Alerton / Honeywell",
		[19] = "TAC AB",
		[20] = "Hewlett-Packard Company",
		[21] = "Dorsette.s Inc.",
		[22] = "Siemens Schweiz AG (Formerly: Cerberus AG)",
		[23] = "York Controls Group",
		[24] = "Automated Logic Corporation",
		[25] = "CSI Control Systems International",
		[26] = "Phoenix Controls Corporation",
		[27] = "Innovex Technologies Inc.",
		[28] = "KMC Controls Inc.",
		[29] = "Xn Technologies Inc.",
		[30] = "Hyundai Information Technology Co. Ltd.",
		[31] = "Tokimec Inc.",
		[32] = "Simplex",
		[33] = "North Building Technologies Limited",
		[34] = "Notifier",
		[35] = "Reliable Controls Corporation",
		[36] = "Tridium Inc.",
		[37] = "Sierra Monitor Corporation/FieldServer Technologies",
		[38] = "Silicon Energy",
		[39] = "Kieback & Peter GmbH & Co KG",
		[40] = "Anacon Systems Inc.",
		[41] = "Systems Controls & Instruments LLC",
		[42] = "Lithonia Lighting",
		[43] = "Micropower Manufacturing",
		[44] = "Matrix Controls",
		[45] = "METALAIRE",
		[46] = "ESS Engineering",
		[47] = "Sphere Systems Pty Ltd.",
		[48] = "Walker Technologies Corporation",
		[49] = "H I Solutions Inc.",
		[50] = "MBS GmbH",
		[51] = "SAMSON AG",
		[52] = "Badger Meter Inc.",
		[53] = "DAIKIN Industries Ltd.",
		[54] = "NARA Controls Inc.",
		[55] = "Mammoth Inc.",
		[56] = "Liebert Corporation",
		[57] = "SEMCO Incorporated",
		[58] = "Air Monitor Corporation",
		[59] = "TRIATEK LLC",
		[60] = "NexLight",
		[61] = "Multistack",
		[62] = "TSI Incorporated",
		[63] = "Weather-Rite Inc.",
		[64] = "Dunham-Bush",
		[65] = "Reliance Electric",
		[66] = "LCS Inc.",
		[67] = "Regulator Australia PTY Ltd.",
		[68] = "Touch-Plate Lighting Controls",
		[69] = "Amann GmbH",
		[70] = "RLE Technologies",
		[71] = "Cardkey Systems",
		[72] = "SECOM Co. Ltd.",
		[73] = "ABB Gebäetechnik AG Bereich NetServ",
		[74] = "KNX Association cvba",
		[75] = "Institute of Electrical Installation Engineers of Japan (IEIEJ)",
		[76] = "Nohmi Bosai Ltd.",
		[77] = "Carel S.p.A.",
		[78] = "AirSense Technology Inc.",
		[79] = "Hochiki Corporation",
		[80] = "Fr. Sauter AG",
		[81] = "Matsushita Electric Works Ltd.",
		[82] = "Mitsubishi Electric Corporation Inazawa Works",
		[83] = "Mitsubishi Heavy Industries Ltd.",
		[84] = "ITT Bell & Gossett",
		[85] = "Yamatake Building Systems Co. Ltd.",
		[86] = "The Watt Stopper Inc.",
		[87] = "Aichi Tokei Denki Co. Ltd.",
		[88] = "Activation Technologies LLC",
		[89] = "Saia-Burgess Controls Ltd.",
		[90] = "Hitachi Ltd.",
		[91] = "Novar Corp./Trend Control Systems Ltd.",
		[92] = "Mitsubishi Electric Lighting Corporation",
		[93] = "Argus Control Systems Ltd.",
		[94] = "Kyuki Corporation",
		[95] = "Richards-Zeta Building Intelligence Inc.",
		[96] = "Scientech R&D Inc.",
		[97] = "VCI Controls Inc.",
		[98] = "Toshiba Corporation",
		[99] = "Mitsubishi Electric Corporation Air Conditioning & Refrigeration Systems Works",
		[100] = "Custom Mechanical Equipment LLC",
		[101] = "ClimateMaster",
		[102] = "ICP Panel-Tec Inc.",
		[103] = "D-Tek Controls",
		[104] = "NEC Engineering Ltd.",
		[105] = "PRIVA BV",
		[106] = "Meidensha Corporation",
		[107] = "JCI Systems Integration Services",
		[108] = "Freedom Corporation",
		[109] = "Neuberger Gebäeautomation GmbH",
		[110] = "Sitronix",
		[111] = "Leviton Manufacturing",
		[112] = "Fujitsu Limited",
		[113] = "Emerson Network Power",
		[114] = "S. A. Armstrong Ltd.",
		[115] = "Visonet AG",
		[116] = "M&M Systems Inc.",
		[117] = "Custom Software Engineering",
		[118] = "Nittan Company Limited",
		[119] = "Elutions Inc. (Wizcon Systems SAS)",
		[120] = "Pacom Systems Pty. Ltd.",
		[121] = "Unico Inc.",
		[122] = "Ebtron Inc.",
		[123] = "Scada Engine",
		[124] = "AC Technology Corporation",
		[125] = "Eagle Technology",
		[126] = "Data Aire Inc.",
		[127] = "ABB Inc.",
		[128] = "Transbit Sp. z o. o.",
		[129] = "Toshiba Carrier Corporation",
		[130] = "Shenzhen Junzhi Hi-Tech Co. Ltd.",
		[131] = "Tokai Soft",
		[132] = "Blue Ridge Technologies",
		[133] = "Veris Industries",
		[134] = "Centaurus Prime",
		[135] = "Sand Network Systems",
		[136] = "Regulvar Inc.",
		[137] = "AFDtek Division of Fastek International Inc.",
		[138] = "PowerCold Comfort Air Solutions Inc.",
		[139] = "I Controls",
		[140] = "Viconics Electronics Inc.",
		[141] = "Yaskawa America Inc.",
		[142] = "DEOS control systems GmbH",
		[143] = "Digitale Mess- und Steuersysteme AG",
		[144] = "Fujitsu General Limited",
		[145] = "Project Engineering S.r.l.",
		[146] = "Sanyo Electric Co. Ltd.",
		[147] = "Integrated Information Systems Inc.",
		[148] = "Temco Controls Ltd.",
		[149] = "Airtek International Inc.",
		[150] = "Advantech Corporation",
		[151] = "Titan Products Ltd.",
		[152] = "Regel Partners",
		[153] = "National Environmental Product",
		[154] = "Unitec Corporation",
		[155] = "Kanden Engineering Company",
		[156] = "Messner Gebäetechnik GmbH",
		[157] = "Integrated.CH",
		[158] = "Price Industries",
		[159] = "SE-Elektronic GmbH",
		[160] = "Rockwell Automation",
		[161] = "Enflex Corp.",
		[162] = "ASI Controls",
		[163] = "SysMik GmbH Dresden",
		[164] = "HSC Regelungstechnik GmbH",
		[165] = "Smart Temp Australia Pty. Ltd.",
		[166] = "Cooper Controls",
		[167] = "Duksan Mecasys Co. Ltd.",
		[168] = "Fuji IT Co. Ltd.",
		[169] = "Vacon Plc",
		[170] = "Leader Controls",
		[171] = "Cylon Controls Ltd.",
		[172] = "Compas",
		[173] = "Mitsubishi Electric Building Techno-Service Co. Ltd.",
		[174] = "Building Control Integrators",
		[175] = "ITG Worldwide (M) Sdn Bhd",
		[176] = "Lutron Electronics Co. Inc.",
		[178] = "LOYTEC Electronics GmbH",
		[179] = "ProLon",
		[180] = "Mega Controls Limited",
		[181] = "Micro Control Systems Inc.",
		[182] = "Kiyon Inc.",
		[183] = "Dust Networks",
		[184] = "Advanced Building Automation Systems",
		[185] = "Hermos AG",
		[186] = "CEZIM",
		[187] = "Softing",
		[188] = "Lynxspring",
		[189] = "Schneider Toshiba Inverter Europe",
		[190] = "Danfoss Drives A/S",
		[191] = "Eaton Corporation",
		[192] = "Matyca S.A.",
		[193] = "Botech AB",
		[194] = "Noveo Inc.",
		[195] = "AMEV",
		[196] = "Yokogawa Electric Corporation",
		[197] = "GFR Gesellschaft füelungstechnik",
		[198] = "Exact Logic",
		[199] = "Mass Electronics Pty Ltd dba Innotech Control Systems Australia",
		[200] = "Kandenko Co. Ltd.",
		[201] = "DTF Daten-Technik Fries",
		[202] = "Klimasoft Ltd.",
		[203] = "Toshiba Schneider Inverter Corporation",
		[204] = "Control Applications Ltd.",
		[205] = "KDT Systems Co. Ltd.",
		[206] = "Onicon Incorporated",
		[207] = "Automation Displays Inc.",
		[208] = "Control Solutions Inc.",
		[209] = "Remsdaq Limited",
		[210] = "NTT Facilities Inc.",
		[211] = "VIPA GmbH",
		[212] = "TSC21 Association of Japan",
		[213] = "Strato Automation",
		[214] = "HRW Limited",
		[215] = "Lighting Control & Design Inc.",
		[216] = "Mercy Electronic and Electrical Industries",
		[217] = "Samsung SDS Co.Ltd",
		[218] = "Impact Facility Solutions Inc.",
		[219] = "Aircuity",
		[220] = "Control Techniques Ltd.",
		[221] = "OpenGeneral Pty. Ltd.",
		[222] = "WAGO Kontakttechnik GmbH & Co. KG",
		[223] = "Cerus Industrial",
		[224] = "Chloride Power Protection Company",
		[225] = "Computrols Inc.",
		[226] = "Phoenix Contact GmbH & Co. KG",
		[227] = "Grundfos Management A/S",
		[228] = "Ridder Drive Systems",
		[229] = "Soft Device SDN BHD",
		[230] = "Integrated Control Technology Limited",
		[231] = "AIRxpert Systems Inc.",
		[232] = "Microtrol Limited",
		[233] = "Red Lion Controls",
		[234] = "Digital Electronics Corporation",
		[235] = "Ennovatis GmbH",
		[236] = "Serotonin Software Technologies Inc.",
		[237] = "LS Industrial Systems Co. Ltd.",
		[238] = "Square D Company",
		[239] = "S Squared Innovations Inc.",
		[240] = "Aricent Ltd.",
		[241] = "EtherMetrics LLC",
		[242] = "Industrial Control Communications Inc.",
		[243] = "Paragon Controls Inc.",
		[244] = "A. O. Smith Corporation",
		[245] = "Contemporary Control Systems Inc.",
		[246] = "Intesis Software SL",
		[247] = "Ingenieurgesellschaft N. Hartleb mbH",
		[248] = "Heat-Timer Corporation",
		[249] = "Ingrasys Technology Inc.",
		[250] = "Costerm Building Automation",
		[251] = "WILO SE",
		[252] = "Embedia Technologies Corp.",
		[253] = "Technilog",
		[254] = "HR Controls Ltd. & Co. KG",
		[255] = "Lennox International Inc.",
		[256] = "RK-Tec Rauchklappen-Steuerungssysteme GmbH & Co. KG",
		[257] = "Thermomax Ltd.",
		[258] = "ELCON Electronic Control Ltd.",
		[259] = "Larmia Control AB",
		[260] = "BACnet Stack at SourceForge",
		[261] = "G4S Security Services A/S",
		[262] = "Exor International S.p.A.",
		[263] = "Cristal Controles",
		[264] = "Regin AB",
		[265] = "Dimension Software Inc.",
		[266] = "SynapSense Corporation",
		[267] = "Beijing Nantree Electronic Co. Ltd.",
		[268] = "Camus Hydronics Ltd.",
		[269] = "Kawasaki Heavy Industries Ltd.",
		[270] = "Critical Environment Technologies",
		[271] = "ILSHIN IBS Co. Ltd.",
		[272] = "ELESTA Energy Control AG",
		[273] = "KROPMAN Installatietechniek",
		[274] = "Baldor Electric Company",
		[275] = "INGA mbH",
		[276] = "GE Consumer & Industrial",
		[277] = "Functional Devices Inc.",
		[278] = "ESAC",
		[279] = "M-System Co. Ltd.",
		[280] = "Yokota Co. Ltd.",
		[281] = "Hitranse Technology Co.LTD",
		[282] = "Federspiel Controls",
		[283] = "Kele Inc.",
		[284] = "Opera Electronics Inc.",
		[285] = "Gentec",
		[286] = "Embedded Science Labs LLC",
		[287] = "Parker Hannifin Corporation",
		[288] = "MaCaPS International Limited",
		[289] = "Link4 Corporation",
		[290] = "Romutec Steuer-u. Regelsysteme GmbH",
		[291] = "Pribusin Inc.",
		[292] = "Advantage Controls",
		[293] = "Critical Room Control",
		[294] = "LEGRAND",
		[295] = "Tongdy Control Technology Co. Ltd.",
		[296] = "ISSARO Integrierte Systemtechnik",
		[297] = "Pro-Dev Industries",
		[298] = "DRI-STEEM",
		[299] = "Creative Electronic GmbH",
		[300] = "Swegon AB",
		[301] = "Jan Brachacek",
		[302] = "Hitachi Appliances Inc.",
		[303] = "Real Time Automation Inc.",
		[304] = "ITEC Hankyu-Hanshin Co.",
		[305] = "Cyrus E&M Engineering Co. Ltd.",
		[306] = "Racine Federated Inc.",
		[307] = "Cirrascale Corporation",
		[308] = "Elesta GmbH Building Automation",
		[309] = "Securiton",
		[310] = "OSlsoft Inc.",
		[311] = "Hanazeder Electronic GmbH",
		[312] = "Honeywell Security DeutschlandNovar GmbH",
		[313] = "Siemens Energy & Automation Inc.",
		[314] = "ETM Professional Control GmbH",
		[315] = "Meitav-tec Ltd.",
		[316] = "Janitza Electronics GmbH",
		[317] = "MKS Nordhausen",
		[318] = "De Gier Drive Systems B.V.",
		[319] = "Cypress Envirosystems",
		[320] = "SMARTron s.r.o.",
		[321] = "Verari Systems Inc.",
		[322] = "K-W Electronic Service Inc.",
		[323] = "ALFA-SMART Energy Management",
		[324] = "Telkonet Inc.",
		[325] = "Securiton GmbH",
		[326] = "Cemtrex Inc.",
		[327] = "Performance Technologies Inc.",
		[328] = "Xtralis (Aust) Pty Ltd",
		[329] = "TROX GmbH",
		[330] = "Beijing Hysine Technology Co.Ltd",
		[331] = "RCK Controls Inc.",
		[332] = "Distech Controls SAS",
		[333] = "Novar/Honeywell",
		[334] = "The S4 Group Inc.",
		[335] = "Schneider Electric",
		[336] = "LHA Systems",
		[337] = "GHM engineering Group Inc.",
		[338] = "Cllimalux S.A.",
		[339] = "VAISALA Oyj",
		[340] = "COMPLEX (Beijing) TechnologyCo. Ltd.",
		[341] = "SCADAmetrics",
		[342] = "POWERPEG NSI Limited",
		[343] = "BACnet Interoperability Testing Services Inc.",
		[344] = "Teco a.s.",
		[345] = "Plexus Technology Inc.",
		[346] = "Energy Focus Inc.",
		[347] = "Powersmiths International Corp.",
		[348] = "Nichibei Co. Ltd.",
		[349] = "HKC Technology Ltd.",
		[350] = "Ovation Networks Inc.",
		[351] = "Setra Systems",
		[352] = "AVG Automation",
		[353] = "ZXC Ltd.",
		[354] = "Byte Sphere",
		[355] = "Generiton Co. Ltd.",
		[356] = "Holter Regelarmaturen GmbH & Co. KG",
		[357] = "Bedford Instruments LLC",
		[358] = "Standair Inc.",
		[359] = "WEG Automation - R&D",
		[360] = "Prolon Control Systems ApS",
		[361] = "Inneasoft",
		[362] = "ConneXSoft GmbH",
		[363] = "CEAG Notlichtsysteme GmbH",
		[364] = "Distech Controls Inc.",
		[365] = "Industrial Technology Research Institute",
		[366] = "ICONICS Inc.",
		[367] = "IQ Controls s.c.",
		[368] = "OJ Electronics A/S",
		[369] = "Rolbit Ltd.",
		[370] = "Synapsys Solutions Ltd.",
		[371] = "ACME Engineering Prod. Ltd.",
		[372] = "Zener Electric Pty Ltd.",
		[373] = "Selectronix Inc.",
		[374] = "Gorbet & Banerjee LLC.",
		[375] = "IME",
		[376] = "Stephen H. Dawson Computer Service",
		[377] = "Accutrol LLC",
		[378] = "Schneider Elektronik GmbH",
		[379] = "Alpha-Inno Tec GmbH",
		[380] = "ADMMicro Inc.",
		[381] = "Greystone Energy Systems Inc.",
		[382] = "CAP Technologie",
		[383] = "KeRo Systems",
		[384] = "Domat Control System s.r.o.",
		[385] = "Efektronics Pty. Ltd.",
		[386] = "Hekatron Vertriebs GmbH",
		[387] = "Securiton AG",
		[388] = "Carlo Gavazzi Controls SpA",
		[389] = "Chipkin Automation Systems",
		[390] = "Savant Systems LLC",
		[391] = "Simmtronic Lighting Controls",
		[392] = "Abelko Innovation AB",
		[393] = "Seresco Technologies Inc.",
		[394] = "IT Watchdogs",
		[395] = "Automation Assist Japan Corp.",
		[396] = "Thermokon Sensortechnik GmbH",
		[397] = "EGauge Systems LLC",
		[398] = "Quantum Automation (ASIA) PTE Ltd.",
		[399] = "Toshiba Lighting & Technology Corp.",
		[400] = "SPIN Engenharia de Automaç Ltda.",
		[401] = "Logistics Systems & Software Services India PVT. Ltd.",
		[402] = "Delta Controls Integration Products",
		[403] = "Focus Media",
		[404] = "LUMEnergi Inc.",
		[405] = "Kara Systems",
		[406] = "RF Code Inc.",
		[407] = "Fatek Automation Corp.",
		[408] = "JANDA Software Company LLC",
		[409] = "Open System Solutions Limited",
		[410] = "Intelec Systems PTY Ltd.",
		[411] = "Ecolodgix LLC",
		[412] = "Douglas Lighting Controls",
		[413] = "iSAtech GmbH",
		[414] = "AREAL",
		[415] = "Beckhoff Automation GmbH",
		[416] = "IPAS GmbH",
		[417] = "KE2 Therm Solutions",
		[418] = "Base2Products",
		[419] = "DTL Controls LLC",
		[420] = "INNCOM International Inc.",
		[421] = "BTR Netcom GmbH",
		[422] = "Greentrol AutomationInc",
		[423] = "BELIMO Automation AG",
		[424] = "Samsung Heavy Industries CoLtd",
		[425] = "Triacta Power Technologies Inc.",
		[426] = "Globestar Systems",
		[427] = "MLB Advanced MediaLP",
		[428] = "SWG Stuckmann Wirtschaftliche Gebäesysteme GmbH",
		[429] = "SensorSwitch",
		[430] = "Multitek Power Limited",
		[431] = "Aquametro AG",
		[432] = "LG Electronics Inc.",
		[433] = "Electronic Theatre Controls Inc.",
		[434] = "Mitsubishi Electric Corporation Nagoya Works",
		[435] = "Delta Electronics Inc.",
		[436] = "Elma Kurtalj Ltd.",
		[437] = "ADT Fire and Security Sp. A.o.o.",
		[438] = "Nedap Security Management",
		[439] = "ESC Automation Inc.",
		[440] = "DSP4YOU Ltd.",
		[441] = "GE Sensing and Inspection Technologies",
		[442] = "Embedded Systems SIA",
		[443] = "BEFEGA GmbH",
		[444] = "Baseline Inc.",
		[445] = "M2M Systems Integrators",
		[446] = "OEMCtrl",
		[447] = "Clarkson Controls Limited",
		[448] = "Rogerwell Control System Limited",
		[449] = "SCL Elements",
		[450] = "Hitachi Ltd.",
		[451] = "Newron System SA",
		[452] = "BEVECO Gebouwautomatisering BV",
		[453] = "Streamside Solutions",
		[454] = "Yellowstone Soft",
		[455] = "Oztech Intelligent Systems Pty Ltd.",
		[456] = "Novelan GmbH",
		[457] = "Flexim Americas Corporation",
		[458] = "ICP DAS Co. Ltd.",
		[459] = "CARMA Industries Inc.",
		[460] = "Log-One Ltd.",
		[461] = "TECO Electric & Machinery Co. Ltd.",
		[462] = "ConnectEx Inc.",
		[463] = "Turbo DDC Sü",
		[464] = "Quatrosense Environmental Ltd.",
		[465] = "Fifth Light Technology Ltd.",
		[466] = "Scientific Solutions Ltd.",
		[467] = "Controller Area Network Solutions (M) Sdn Bhd",
		[468] = "RESOL - Elektronische Regelungen GmbH",
		[469] = "RPBUS LLC",
		[470] = "BRS Sistemas Eletronicos",
		[471] = "WindowMaster A/S",
		[472] = "Sunlux Technologies Ltd.",
		[473] = "Measurlogic",
		[474] = "Frimat GmbH",
		[475] = "Spirax Sarco",
		[476] = "Luxtron",
		[477] = "Raypak Inc",
		[478] = "Air Monitor Corporation",
		[479] = "Regler Och Webbteknik Sverige (ROWS)",
		[480] = "Intelligent Lighting Controls Inc.",
		[481] = "Sanyo Electric Industry Co.Ltd",
		[482] = "E-Mon Energy Monitoring Products",
		[483] = "Digital Control Systems",
		[484] = "ATI Airtest Technologies Inc.",
		[485] = "SCS SA",
		[486] = "HMS Industrial Networks AB",
		[487] = "Shenzhen Universal Intellisys Co Ltd",
		[488] = "EK Intellisys Sdn Bhd",
		[489] = "SysCom",
		[490] = "Firecom Inc.",
		[491] = "ESA Elektroschaltanlagen Grimma GmbH",
		[492] = "Kumahira Co Ltd",
		[493] = "Hotraco",
		[494] = "SABO Elektronik GmbH",
		[495] = "Equip'Trans",
		[496] = "TCS Basys Controls",
		[497] = "FlowCon International A/S",
		[498] = "ThyssenKrupp Elevator Americas",
		[499] = "Abatement Technologies",
		[500] = "Continental Control Systems LLC",
		[501] = "WISAG Automatisierungstechnik GmbH & Co KG",
		[502] = "EasyIO",
		[503] = "EAP-Electric GmbH",
		[504] = "Hardmeier",
		[505] = "Mircom Group of Companies",
		[506] = "Quest Controls",
		[507] = "MestekInc",
		[508] = "Pulse Energy",
		[509] = "Tachikawa Corporation",
		[510] = "University of Nebraska-Lincoln",
		[511] = "Redwood Systems",
		[512] = "PASStec Industrie-Elektronik GmbH",
		[513] = "NgEK Inc.",
		[514] = "FAW Electronics Ltd",
		[515] = "Jireh Energy Tech Co. Ltd.",
		[516] = "Enlighted Inc.",
		[517] = "El-Piast Sp. Z o.o",
		[518] = "NetxAutomation Software GmbH",
		[519] = "Invertek Drives",
		[520] = "Deutschmann Automation GmbH & Co. KG",
		[521] = "EMU Electronic AG",
		[522] = "Phaedrus Limited",
		[523] = "Sigmatek GmbH & Co KG",
		[524] = "Marlin Controls",
		[525] = "CircutorSA",
		[526] = "UTC Fire & Security",
		[527] = "DENT Instruments Inc.",
		[528] = "FHP Manufacturing Company - Bosch Group",
		[529] = "GE Intelligent Platforms",
		[530] = "Inner Range Pty Ltd",
		[531] = "GLAS Energy Technology",
		[532] = "MSR-Electronic-GmbH",
		[533] = "Energy Control Systems Inc.",
		[534] = "EMT Controls",
		[535] = "Daintree Networks Inc.",
		[536] = "EURO ICC d.o.o",
		[537] = "TE Connectivity Energy",
		[538] = "GEZE GmbH",
		[539] = "NEC Corporation",
		[540] = "Ho Cheung International Company Limited",
		[541] = "Sharp Manufacturing Systems Corporation",
		[542] = "DOT CONTROLS a.s.",
		[543] = "BeaconMedæ0220",
		[544] = "Midea Commercial Aircon",
		[545] = "WattMaster Controls",
		[546] = "Kamstrup A/S",
		[547] = "CA Computer Automation GmbH",
		[548] = "Laars Heating Systems Company",
		[549] = "Hitachi Systems Ltd.",
		[550] = "Fushan AKE Electronic Engineering Co. Ltd.",
		[551] = "Toshiba International Corporation",
		[552] = "Starman Systems LLC",
		[553] = "Samsung Techwin Co. Ltd.",
		[554] = "ISAS-Integrated Switchgear and Systems P/L",
		[556] = "Obvius",
		[557] = "Marek Guzik",
		[558] = "Vortek Instruments LLC",
		[559] = "Universal Lighting Technologies",
		[560] = "Myers Power Products Inc.",
		[561] = "Vector Controls GmbH",
		[562] = "Crestron Electronics Inc.",
		[563] = "A&E Controls Limited",
		[564] = "Projektomontaza A.D.",
		[565] = "Freeaire Refrigeration",
		[566] = "Aqua Cooler Pty Limited",
		[567] = "Basic Controls",
		[568] = "GE Measurement and Control Solutions Advanced Sensors",
		[569] = "EQUAL Networks",
		[570] = "Millennial Net",
		[571] = "APLI Ltd",
		[572] = "Electro Industries/GaugeTech",
		[573] = "SangMyung University",
		[574] = "Coppertree Analytics Inc.",
		[575] = "CoreNetiX GmbH",
		[576] = "Acutherm",
		[577] = "Dr. Riedel Automatisierungstechnik GmbH",
		[578] = "Shina System Co.Ltd",
		[579] = "Iqapertus",
		[580] = "PSE Technology",
		[581] = "BA Systems",
		[582] = "BTICINO",
		[583] = "Monico Inc.",
		[584] = "iCue",
		[585] = "tekmar Control Systems Ltd.",
		[586] = "Control Technology Corporation",
		[587] = "GFAE GmbH",
		[588] = "BeKa Software GmbH",
		[589] = "Isoil Industria SpA",
		[590] = "Home Systems Consulting SpA",
		[591] = "Socomec",
		[592] = "Everex Communications Inc.",
		[593] = "Ceiec Electric Technology",
		[594] = "Atrila GmbH",
		[595] = "WingTechs",
		[596] = "Shenzhen Mek Intellisys Pte Ltd.",
		[597] = "Nestfield Co. Ltd.",
		[598] = "Swissphone Telecom AG",
		[599] = "PNTECH JSC",
		[600] = "Horner APG LLC",
		[601] = "PVI Industries LLC",
		[602] = "Ela-compil",
		[603] = "Pegasus Automation International LLC",
		[604] = "Wight Electronic Services Ltd.",
		[605] = "Marcom",
		[606] = "Exhausto A/S",
		[607] = "Dwyer Instruments Inc.",
		[608] = "Link GmbH",
		[609] = "Oppermann Regelgerate GmbH",
		[610] = "NuAire Inc.",
		[611] = "Nortec Humidity Inc.",
		[612] = "Bigwood Systems Inc.",
		[613] = "Enbala Power Networks",
		[614] = "Inter Energy Co. Ltd.",
		[615] = "ETC",
		[616] = "COMELEC S.A.R.L",
		[617] = "Pythia Technologies",
		[618] = "TrendPoint Systems Inc.",
		[619] = "AWEX",
		[620] = "Eurevia",
		[621] = "Kongsberg E-lon AS",
		[622] = "FlaktWoods",
		[623] = "E + E Elektronik GES M.B.H.",
		[624] = "ARC Informatique",
		[625] = "SKIDATA AG",
		[626] = "WSW Solutions",
		[627] = "Trefon Electronic GmbH",
		[628] = "Dongseo System",
		[629] = "Kanontec Intelligence Technology Co. Ltd.",
		[630] = "EVCO S.p.A.",
		[631] = "Accuenergy (CANADA) Inc.",
		[632] = "SoftDEL",
		[633] = "Orion Energy Systems Inc.",
		[634] = "Roboticsware",
		[635] = "DOMIQ Sp. z o.o.",
		[636] = "Solidyne",
		[637] = "Elecsys Corporation",
		[638] = "Conditionaire International Pty. Limited",
		[639] = "Quebec Inc.",
		[640] = "Homerun Holdings",
		[641] = "RFM Inc.",
		[642] = "Comptek",
		[643] = "Westco Systems Inc.",
		[644] = "Advancis Software & Services GmbH",
		[645] = "Intergrid LLC",
		[646] = "Markerr Controls Inc.",
		[647] = "Toshiba Elevator and Building Systems Corporation",
		[648] = "Spectrum Controls Inc.",
		[649] = "Mkservice",
		[650] = "Fox Thermal Instruments",
		[651] = "SyxthSense Ltd",
		[652] = "DUHA System S R.O.",
		[653] = "NIBE",
		[654] = "Melink Corporation",
		[655] = "Fritz-Haber-Institut",
		[656] = "MTU Onsite Energy GmbHGas Power Systems",
		[657] = "Omega Engineering Inc.",
		[658] = "Avelon",
		[659] = "Ywire Technologies Inc.",
		[660] = "M.R. Engineering Co. Ltd.",
		[661] = "Lochinvar LLC",
		[662] = "Sontay Limited",
		[663] = "GRUPA Slawomir Chelminski",
		[664] = "Arch Meter Corporation",
		[665] = "Senva Inc.",
		[667] = "FM-Tec",
		[668] = "Systems Specialists Inc.",
		[669] = "SenseAir",
		[670] = "AB IndustrieTechnik Srl",
		[671] = "Cortland Research LLC",
		[672] = "MediaView",
		[673] = "VDA Elettronica",
		[674] = "CSS Inc.",
		[675] = "Tek-Air Systems Inc.",
		[676] = "ICDT",
		[677] = "The Armstrong Monitoring Corporation",
		[678] = "DIXELL S.r.l",
		[679] = "Lead System Inc.",
		[680] = "ISM EuroCenter S.A.",
		[681] = "TDIS",
		[682] = "Trade FIDES",
		[683] = "KnübH (Emerson Network Power)",
		[684] = "Resource Data Management",
		[685] = "Abies Technology Inc.",
		[686] = "Amalva",
		[687] = "MIRAE Electrical Mfg. Co. Ltd.",
		[688] = "HunterDouglas Architectural Projects Scandinavia ApS",
		[689] = "RUNPAQ Group Co.Ltd",
		[690] = "Unicard SA",
		[691] = "IE Technologies",
		[692] = "Ruskin Manufacturing",
		[693] = "Calon Associates Limited",
		[694] = "Contec Co. Ltd.",
		[695] = "iT GmbH",
		[696] = "Autani Corporation",
		[697] = "Christian Fortin",
		[698] = "HDL",
		[699] = "IPID Sp. Z.O.O Limited",
		[700] = "Fuji Electric Co.Ltd",
		[701] = "View Inc.",
		[702] = "Samsung S1 Corporation",
		[703] = "New Lift",
		[704] = "VRT Systems",
		[705] = "Motion Control Engineering Inc.",
		[706] = "Weiss Klimatechnik GmbH",
		[707] = "Elkon",
		[708] = "Eliwell Controls S.r.l.",
		[709] = "Japan Computer Technos Corp",
		[710] = "Rational Network ehf",
		[711] = "Magnum Energy Solutions LLC",
		[712] = "MelRok",
		[713] = "VAE Group",
		[714] = "LGCNS",
		[715] = "Berghof Automationstechnik GmbH",
		[716] = "Quark Communications Inc.",
		[717] = "Sontex",
		[718] = "mivune AG",
		[719] = "Panduit",
		[720] = "Smart Controls LLC",
		[721] = "Compu-Aire Inc.",
		[722] = "Sierra",
		[723] = "ProtoSense Technologies",
		[724] = "Eltrac Technologies Pvt Ltd",
		[725] = "Bektas Invisible Controls GmbH",
		[726] = "Entelec",
		[727] = "Innexiv",
		[728] = "Covenant"
	}
	--return vendor information
	if(vendor_id[vennum] ~= nil) then
		return vendor_id[vennum]
	else
		return "Unknown Vendor Number"
	end
end 

--
-- iterate through the packet to gather firmware information 
--
--
function loop_packet(packet)
	--variable delcration
	local value = nil
	local first_char = nil
	local second_char = nil
	local i = 0
	local info = ""
	-- read the Length field from the packet data byte 19
	value = tonumber(packet[37] .. packet[38],16) - 1
	
	if ( packet[36] < tostring(5) ) then
		value = packet[36] - 1
		offset = 39 
	else	
		offset = 41
	end
	value = value * 2
	while ( i < value) do 
		-- data byte 20 is the start of the firmware version if field is not 0x75, then use the last number (5) to read size
		-- read character 1
		first_char=  packet[offset + i] 
		i = i + 1
		--read character 2
		second_char = packet[offset + i] 
		i = i + 1
		-- convert to decimal and add to previous string
		info = info .. string.format("%c", tonumber(first_char .. second_char, 16)) 
						
	end
	-- return information that was found in the packet  				
	return info				
end
--
--convert the response to a hex character table 
--
--
function convert_response(response)

	string_resp = stdnse.tohex(response)
	tresp = {};
	
	for i = 1, #string_resp do
		c = string_resp:sub(i,i)
		tresp[i] = c
	end
	-- return the table 
	return tresp
	
end
--
-- function to set the nmap output paramaters
--
--
function set_nmap(host, port)

	--set port Open
	port.state = "open"
	-- set version name to BACNet
	port.version.name = "BACNet -- Building Automation and Control Networks"
	nmap.set_port_version(host, port)
	nmap.set_port_state(host, port, "open")

end
--
--
-- Many requests require the same parsing, this function is designed to pull that information based off
-- a standard query parseing.
--
function standard_query(socket, type, type_string)

	-- set the firmware version query data for sending
	local firmware_query = bin.pack( "H","810a001101040005010c0c023FFFFF192c") 
	-- set the firmware version query data for sending
	local appsoft_query = bin.pack( "H","810a001101040005010c0c023FFFFF190c")
	-- set the object name query data for sending
	local object_query = bin.pack("H","810a001101040005010c0c023FFFFF194d")
	-- set the model name query data for sending
	local model_query = bin.pack("H","810a001101040005010c0c023FFFFF1946")
	-- set the desc name query data for sending
	local desc_query = bin.pack("H","810a001101040005010c0c023FFFFF191c")
	-- set the location name query data for sending
	local location_query = bin.pack("H","810a001101040005010c0c023FFFFF193A")
	local query = ""
	
	--
	-- determine what type of packet to send
	if (type == "firmware") then
		query = firmware_query
	elseif (type == "application") then
		query = appsoft_query
	elseif (type == "model") then
		query = model_query
	elseif (type == "object") then
		query = object_query
	elseif (type == "description") then
		query = desc_query
	elseif (type == "location") then
		query = location_query
	end
	
	--try to pull the  information	
	local status, result = socket:send(query)
	if(result == false) then
		return false, response
	end
	-- recieve packet from reponse
	local rcvstatus, response = socket:receive()
	if(rcvstatus == false) then
		return false, response
	end
	-- validate valid BACNet Packet	
	if( string.starts(response, "\x81")) then	
		-- convert response to character table
		local tresp = convert_response(response)
		-- verify that the response packet was not an error packet
		if( tresp[13] .. tresp[14] ~= "50") then
			--collect information by looping thru the packet
			local result = loop_packet(tresp)
			return type_string .. ": " .. tostring(result)
		-- if it was an error packet
		else
			socket:close()
			return type_string .. ": ERROR \n\t" .. string_resp  
		end
			-- else ERROR			
	else
		return type_string .. ": ERROR \n\t" .. string_resp 
	end
	
end
--
-- Function to send and recieve the packet needed to parse vendor information
-- Then call the function to lookup vendor name/number
--
function vendornum_query(socket)

	-- set the vendor query data for sending
	local vendor_query = bin.pack( "H","'810a001101040005010c0c023FFFFF1978")
	
	
	--send the vendor information	
	local status, result = socket:send(vendor_query)
	if(result == false) then
		return false, response
	end
	-- recieve vendor information packet
	local rcvstatus, response = socket:receive()
	if(rcvstatus == false) then
		return false, response
	end
	-- validate valid BACNet Packet
	if( string.starts(response, "\x81")) then
		-- convert response to hex, then to a char table
		local tresp = convert_response(response)
		local value = nil
		--if the vendor query resulted in an error 
		if( tresp[13] .. tresp[14] ~= "50") then
			-- read values for byte 18 in the packet data
			-- this value determines if vendor number is 1 or 2 bytes
			value = tresp[35] .. tresp[36]
		else
			socket:close()
			return "Vendor ID: ERROR \n\t" .. string_resp .. to_return 
		end
		-- if value is 21 (byte 18)
		if( value == "21" ) then
			-- convert hex to decimal
			local vendornum = tonumber(tresp[37] .. tresp[38], 16)
			-- look up vendor name from table 
			local vendorname = vendor_lookup(vendornum)
			return "Vendor ID: " .. vendorname .. " (" .. vendornum .. ")" 
		-- if value is 22 (byte 18)
		elseif( value == "22" ) then
			-- convert hex to decimal
			local vendornum = tonumber(tresp[37] .. tresp[38] .. tresp[39] .. tresp[40], 16)
			-- look up vendor name from table
			local vendorname = vendor_lookup(vendornum)
			-- set vendor name in the varaible that will be returned when done
			return  "Vendor ID: " .. vendorname .. " (" .. vendornum .. ")" 
		else
			-- set return value to an Error if byte 18 was not 21/22
			return "Vendor ID: ERROR " 
		end
	end		

end

--
--
-- main function
-- 
action = function(host, port)
	--varialbe declaration
	local to_return = {}
	--set the first query data for sending
	local orig_query = bin.pack( "H","810a001101040005010c0c023FFFFF194b" )
		
	-- create new socket
	sock = nmap.new_socket()
    -- Bind to port for niceness with BACNet this may need to be commented out if 
	-- scanning more than one host at a time, may fix some issues seen on Windows 
	--
	status, err = sock:bind(nil, 47808)
	if(status == false) then
		return false, err
	end
	-- connect to the remote host on udp port 47808	
    local constatus, conerr = sock:connect(host, 47808, "udp")
	if not constatus then
      stdnse.print_debug(1,
        'Error establishing a UDP connection for %s - %s', host, conerr
      )
      return nil
    end
	-- send the orignal query to see if it is a valid BACNet Device
	local sendstatus, senderr = sock:send(orig_query);
	if not sendstatus then
		stdnse.print_debug(1,
		'Error sending BACNet request to %s:%d - %s',
		host.ip, port.number,  senderr
		)
		return nil
	end
	
	-- receive response 
    local rcvstatus, response = sock:receive()
	if(rcvstatus == false) then
		return false, result
	end
	
	-- if the response starts with 0x81 then its BACNet
	if( string.starts(response, "\x81")) then
		
		-- convert the packet to HEX string
		local tresp = convert_response(response)
		--if the first query resulted in an error 
		--
		if( tresp[13] .. tresp[14] == "50") then
			-- set the nmap output for the port and version
			set_nmap(host, port)
			-- return that BACNet Error was recieved
			to_return = "\nBACNet ADPU Type: Error (5) \n\t" .. stdnse.tohex(response)
		--else pull the InstanceNumber and move onto the pulling more information
		--
		else
			-- set the nmap output for the port and version
			set_nmap(host, port)
			-- Instance Number (object number)
			to_return[2] = "Instance Number: " .. tonumber(tresp[39] .. tresp[40] .. tresp[41] .. tresp[42] .. tresp[43] .. tresp[44], 16) 
			-- Vendor Number to Name lookup
			to_return[1] = vendornum_query(sock) 
			--Firmware Verson
			to_return[3] = standard_query(sock, "firmware", "Firmware")
			-- Application Software Version
			to_return[4] = standard_query(sock, "application", "Application Software")
			-- Object Name
			to_return[5] = standard_query(sock, "object", "Object Name")
			-- Model Name
			to_return[6] = standard_query(sock, "model", "Model Name")
			-- Description
			to_return[7] = standard_query(sock, "description", "Description")
			-- Location
			to_return[8] = standard_query(sock, "location", "Location")		
		
		end
	else
		-- return nothing, no BACNet was detected
		-- close socket
		sock:close()
		return nil
	end
	-- close socket
	sock:close()
	-- return all information that was found
	return stdnse.format_output(true, to_return)
	
end