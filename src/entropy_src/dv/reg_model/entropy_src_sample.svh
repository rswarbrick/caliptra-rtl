// SPDX-License-Identifier: Apache-2.0
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`ifndef ENTROPY_SRC_SAMPLE
    `define ENTROPY_SRC_SAMPLE
    
    /*----------------------- ENTROPY_SRC__INTERRUPT_STATE SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__INTERRUPT_STATE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ES_ENTROPY_VALID_bit_cg[bt]) this.ES_ENTROPY_VALID_bit_cg[bt].sample(data[0 + bt]);
            foreach(ES_HEALTH_TEST_FAILED_bit_cg[bt]) this.ES_HEALTH_TEST_FAILED_bit_cg[bt].sample(data[1 + bt]);
            foreach(ES_OBSERVE_FIFO_READY_bit_cg[bt]) this.ES_OBSERVE_FIFO_READY_bit_cg[bt].sample(data[2 + bt]);
            foreach(ES_FATAL_ERR_bit_cg[bt]) this.ES_FATAL_ERR_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*ES_ENTROPY_VALID*/  ,  data[1:1]/*ES_HEALTH_TEST_FAILED*/  ,  data[2:2]/*ES_OBSERVE_FIFO_READY*/  ,  data[3:3]/*ES_FATAL_ERR*/   );
        end
    endfunction

    function void entropy_src__INTERRUPT_STATE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ES_ENTROPY_VALID_bit_cg[bt]) this.ES_ENTROPY_VALID_bit_cg[bt].sample(ES_ENTROPY_VALID.get_mirrored_value() >> bt);
            foreach(ES_HEALTH_TEST_FAILED_bit_cg[bt]) this.ES_HEALTH_TEST_FAILED_bit_cg[bt].sample(ES_HEALTH_TEST_FAILED.get_mirrored_value() >> bt);
            foreach(ES_OBSERVE_FIFO_READY_bit_cg[bt]) this.ES_OBSERVE_FIFO_READY_bit_cg[bt].sample(ES_OBSERVE_FIFO_READY.get_mirrored_value() >> bt);
            foreach(ES_FATAL_ERR_bit_cg[bt]) this.ES_FATAL_ERR_bit_cg[bt].sample(ES_FATAL_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ES_ENTROPY_VALID.get_mirrored_value()  ,  ES_HEALTH_TEST_FAILED.get_mirrored_value()  ,  ES_OBSERVE_FIFO_READY.get_mirrored_value()  ,  ES_FATAL_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__INTERRUPT_ENABLE SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__INTERRUPT_ENABLE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ES_ENTROPY_VALID_bit_cg[bt]) this.ES_ENTROPY_VALID_bit_cg[bt].sample(data[0 + bt]);
            foreach(ES_HEALTH_TEST_FAILED_bit_cg[bt]) this.ES_HEALTH_TEST_FAILED_bit_cg[bt].sample(data[1 + bt]);
            foreach(ES_OBSERVE_FIFO_READY_bit_cg[bt]) this.ES_OBSERVE_FIFO_READY_bit_cg[bt].sample(data[2 + bt]);
            foreach(ES_FATAL_ERR_bit_cg[bt]) this.ES_FATAL_ERR_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*ES_ENTROPY_VALID*/  ,  data[1:1]/*ES_HEALTH_TEST_FAILED*/  ,  data[2:2]/*ES_OBSERVE_FIFO_READY*/  ,  data[3:3]/*ES_FATAL_ERR*/   );
        end
    endfunction

    function void entropy_src__INTERRUPT_ENABLE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ES_ENTROPY_VALID_bit_cg[bt]) this.ES_ENTROPY_VALID_bit_cg[bt].sample(ES_ENTROPY_VALID.get_mirrored_value() >> bt);
            foreach(ES_HEALTH_TEST_FAILED_bit_cg[bt]) this.ES_HEALTH_TEST_FAILED_bit_cg[bt].sample(ES_HEALTH_TEST_FAILED.get_mirrored_value() >> bt);
            foreach(ES_OBSERVE_FIFO_READY_bit_cg[bt]) this.ES_OBSERVE_FIFO_READY_bit_cg[bt].sample(ES_OBSERVE_FIFO_READY.get_mirrored_value() >> bt);
            foreach(ES_FATAL_ERR_bit_cg[bt]) this.ES_FATAL_ERR_bit_cg[bt].sample(ES_FATAL_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ES_ENTROPY_VALID.get_mirrored_value()  ,  ES_HEALTH_TEST_FAILED.get_mirrored_value()  ,  ES_OBSERVE_FIFO_READY.get_mirrored_value()  ,  ES_FATAL_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__INTERRUPT_TEST SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__INTERRUPT_TEST::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ES_ENTROPY_VALID_bit_cg[bt]) this.ES_ENTROPY_VALID_bit_cg[bt].sample(data[0 + bt]);
            foreach(ES_HEALTH_TEST_FAILED_bit_cg[bt]) this.ES_HEALTH_TEST_FAILED_bit_cg[bt].sample(data[1 + bt]);
            foreach(ES_OBSERVE_FIFO_READY_bit_cg[bt]) this.ES_OBSERVE_FIFO_READY_bit_cg[bt].sample(data[2 + bt]);
            foreach(ES_FATAL_ERR_bit_cg[bt]) this.ES_FATAL_ERR_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*ES_ENTROPY_VALID*/  ,  data[1:1]/*ES_HEALTH_TEST_FAILED*/  ,  data[2:2]/*ES_OBSERVE_FIFO_READY*/  ,  data[3:3]/*ES_FATAL_ERR*/   );
        end
    endfunction

    function void entropy_src__INTERRUPT_TEST::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ES_ENTROPY_VALID_bit_cg[bt]) this.ES_ENTROPY_VALID_bit_cg[bt].sample(ES_ENTROPY_VALID.get_mirrored_value() >> bt);
            foreach(ES_HEALTH_TEST_FAILED_bit_cg[bt]) this.ES_HEALTH_TEST_FAILED_bit_cg[bt].sample(ES_HEALTH_TEST_FAILED.get_mirrored_value() >> bt);
            foreach(ES_OBSERVE_FIFO_READY_bit_cg[bt]) this.ES_OBSERVE_FIFO_READY_bit_cg[bt].sample(ES_OBSERVE_FIFO_READY.get_mirrored_value() >> bt);
            foreach(ES_FATAL_ERR_bit_cg[bt]) this.ES_FATAL_ERR_bit_cg[bt].sample(ES_FATAL_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ES_ENTROPY_VALID.get_mirrored_value()  ,  ES_HEALTH_TEST_FAILED.get_mirrored_value()  ,  ES_OBSERVE_FIFO_READY.get_mirrored_value()  ,  ES_FATAL_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ALERT_TEST SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ALERT_TEST::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(RECOV_ALERT_bit_cg[bt]) this.RECOV_ALERT_bit_cg[bt].sample(data[0 + bt]);
            foreach(FATAL_ALERT_bit_cg[bt]) this.FATAL_ALERT_bit_cg[bt].sample(data[1 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*RECOV_ALERT*/  ,  data[1:1]/*FATAL_ALERT*/   );
        end
    endfunction

    function void entropy_src__ALERT_TEST::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(RECOV_ALERT_bit_cg[bt]) this.RECOV_ALERT_bit_cg[bt].sample(RECOV_ALERT.get_mirrored_value() >> bt);
            foreach(FATAL_ALERT_bit_cg[bt]) this.FATAL_ALERT_bit_cg[bt].sample(FATAL_ALERT.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( RECOV_ALERT.get_mirrored_value()  ,  FATAL_ALERT.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ME_REGWEN SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ME_REGWEN::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ME_REGWEN_bit_cg[bt]) this.ME_REGWEN_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*ME_REGWEN*/   );
        end
    endfunction

    function void entropy_src__ME_REGWEN::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ME_REGWEN_bit_cg[bt]) this.ME_REGWEN_bit_cg[bt].sample(ME_REGWEN.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ME_REGWEN.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__SW_REGUPD SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__SW_REGUPD::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(SW_REGUPD_bit_cg[bt]) this.SW_REGUPD_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*SW_REGUPD*/   );
        end
    endfunction

    function void entropy_src__SW_REGUPD::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(SW_REGUPD_bit_cg[bt]) this.SW_REGUPD_bit_cg[bt].sample(SW_REGUPD.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( SW_REGUPD.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__REGWEN SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__REGWEN::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(REGWEN_bit_cg[bt]) this.REGWEN_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*REGWEN*/   );
        end
    endfunction

    function void entropy_src__REGWEN::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(REGWEN_bit_cg[bt]) this.REGWEN_bit_cg[bt].sample(REGWEN.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( REGWEN.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__REV SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__REV::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ABI_REVISION_bit_cg[bt]) this.ABI_REVISION_bit_cg[bt].sample(data[0 + bt]);
            foreach(HW_REVISION_bit_cg[bt]) this.HW_REVISION_bit_cg[bt].sample(data[8 + bt]);
            foreach(CHIP_TYPE_bit_cg[bt]) this.CHIP_TYPE_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[7:0]/*ABI_REVISION*/  ,  data[15:8]/*HW_REVISION*/  ,  data[23:16]/*CHIP_TYPE*/   );
        end
    endfunction

    function void entropy_src__REV::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ABI_REVISION_bit_cg[bt]) this.ABI_REVISION_bit_cg[bt].sample(ABI_REVISION.get_mirrored_value() >> bt);
            foreach(HW_REVISION_bit_cg[bt]) this.HW_REVISION_bit_cg[bt].sample(HW_REVISION.get_mirrored_value() >> bt);
            foreach(CHIP_TYPE_bit_cg[bt]) this.CHIP_TYPE_bit_cg[bt].sample(CHIP_TYPE.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ABI_REVISION.get_mirrored_value()  ,  HW_REVISION.get_mirrored_value()  ,  CHIP_TYPE.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__MODULE_ENABLE SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__MODULE_ENABLE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(MODULE_ENABLE_bit_cg[bt]) this.MODULE_ENABLE_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[3:0]/*MODULE_ENABLE*/   );
        end
    endfunction

    function void entropy_src__MODULE_ENABLE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(MODULE_ENABLE_bit_cg[bt]) this.MODULE_ENABLE_bit_cg[bt].sample(MODULE_ENABLE.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( MODULE_ENABLE.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__CONF SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__CONF::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_ENABLE_bit_cg[bt]) this.FIPS_ENABLE_bit_cg[bt].sample(data[0 + bt]);
            foreach(FIPS_FLAG_bit_cg[bt]) this.FIPS_FLAG_bit_cg[bt].sample(data[4 + bt]);
            foreach(RNG_FIPS_bit_cg[bt]) this.RNG_FIPS_bit_cg[bt].sample(data[8 + bt]);
            foreach(RNG_BIT_ENABLE_bit_cg[bt]) this.RNG_BIT_ENABLE_bit_cg[bt].sample(data[12 + bt]);
            foreach(RNG_BIT_SEL_bit_cg[bt]) this.RNG_BIT_SEL_bit_cg[bt].sample(data[16 + bt]);
            foreach(THRESHOLD_SCOPE_bit_cg[bt]) this.THRESHOLD_SCOPE_bit_cg[bt].sample(data[18 + bt]);
            foreach(ENTROPY_DATA_REG_ENABLE_bit_cg[bt]) this.ENTROPY_DATA_REG_ENABLE_bit_cg[bt].sample(data[22 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[3:0]/*FIPS_ENABLE*/  ,  data[7:4]/*FIPS_FLAG*/  ,  data[11:8]/*RNG_FIPS*/  ,  data[15:12]/*RNG_BIT_ENABLE*/  ,  data[17:16]/*RNG_BIT_SEL*/  ,  data[21:18]/*THRESHOLD_SCOPE*/  ,  data[25:22]/*ENTROPY_DATA_REG_ENABLE*/   );
        end
    endfunction

    function void entropy_src__CONF::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_ENABLE_bit_cg[bt]) this.FIPS_ENABLE_bit_cg[bt].sample(FIPS_ENABLE.get_mirrored_value() >> bt);
            foreach(FIPS_FLAG_bit_cg[bt]) this.FIPS_FLAG_bit_cg[bt].sample(FIPS_FLAG.get_mirrored_value() >> bt);
            foreach(RNG_FIPS_bit_cg[bt]) this.RNG_FIPS_bit_cg[bt].sample(RNG_FIPS.get_mirrored_value() >> bt);
            foreach(RNG_BIT_ENABLE_bit_cg[bt]) this.RNG_BIT_ENABLE_bit_cg[bt].sample(RNG_BIT_ENABLE.get_mirrored_value() >> bt);
            foreach(RNG_BIT_SEL_bit_cg[bt]) this.RNG_BIT_SEL_bit_cg[bt].sample(RNG_BIT_SEL.get_mirrored_value() >> bt);
            foreach(THRESHOLD_SCOPE_bit_cg[bt]) this.THRESHOLD_SCOPE_bit_cg[bt].sample(THRESHOLD_SCOPE.get_mirrored_value() >> bt);
            foreach(ENTROPY_DATA_REG_ENABLE_bit_cg[bt]) this.ENTROPY_DATA_REG_ENABLE_bit_cg[bt].sample(ENTROPY_DATA_REG_ENABLE.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_ENABLE.get_mirrored_value()  ,  FIPS_FLAG.get_mirrored_value()  ,  RNG_FIPS.get_mirrored_value()  ,  RNG_BIT_ENABLE.get_mirrored_value()  ,  RNG_BIT_SEL.get_mirrored_value()  ,  THRESHOLD_SCOPE.get_mirrored_value()  ,  ENTROPY_DATA_REG_ENABLE.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ENTROPY_CONTROL SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ENTROPY_CONTROL::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ES_ROUTE_bit_cg[bt]) this.ES_ROUTE_bit_cg[bt].sample(data[0 + bt]);
            foreach(ES_TYPE_bit_cg[bt]) this.ES_TYPE_bit_cg[bt].sample(data[4 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[3:0]/*ES_ROUTE*/  ,  data[7:4]/*ES_TYPE*/   );
        end
    endfunction

    function void entropy_src__ENTROPY_CONTROL::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ES_ROUTE_bit_cg[bt]) this.ES_ROUTE_bit_cg[bt].sample(ES_ROUTE.get_mirrored_value() >> bt);
            foreach(ES_TYPE_bit_cg[bt]) this.ES_TYPE_bit_cg[bt].sample(ES_TYPE.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ES_ROUTE.get_mirrored_value()  ,  ES_TYPE.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ENTROPY_DATA SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ENTROPY_DATA::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ENTROPY_DATA_bit_cg[bt]) this.ENTROPY_DATA_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*ENTROPY_DATA*/   );
        end
    endfunction

    function void entropy_src__ENTROPY_DATA::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ENTROPY_DATA_bit_cg[bt]) this.ENTROPY_DATA_bit_cg[bt].sample(ENTROPY_DATA.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ENTROPY_DATA.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__HEALTH_TEST_WINDOWS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__HEALTH_TEST_WINDOWS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WINDOW_bit_cg[bt]) this.FIPS_WINDOW_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WINDOW_bit_cg[bt]) this.BYPASS_WINDOW_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WINDOW*/  ,  data[31:16]/*BYPASS_WINDOW*/   );
        end
    endfunction

    function void entropy_src__HEALTH_TEST_WINDOWS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WINDOW_bit_cg[bt]) this.FIPS_WINDOW_bit_cg[bt].sample(FIPS_WINDOW.get_mirrored_value() >> bt);
            foreach(BYPASS_WINDOW_bit_cg[bt]) this.BYPASS_WINDOW_bit_cg[bt].sample(BYPASS_WINDOW.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WINDOW.get_mirrored_value()  ,  BYPASS_WINDOW.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__REPCNT_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__REPCNT_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__REPCNT_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__REPCNTS_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__REPCNTS_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__REPCNTS_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ADAPTP_HI_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ADAPTP_HI_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__ADAPTP_HI_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ADAPTP_LO_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ADAPTP_LO_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__ADAPTP_LO_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__BUCKET_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__BUCKET_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__BUCKET_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__MARKOV_HI_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__MARKOV_HI_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__MARKOV_HI_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__MARKOV_LO_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__MARKOV_LO_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__MARKOV_LO_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__EXTHT_HI_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__EXTHT_HI_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__EXTHT_HI_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__EXTHT_LO_THRESHOLDS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__EXTHT_LO_THRESHOLDS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_THRESH*/  ,  data[31:16]/*BYPASS_THRESH*/   );
        end
    endfunction

    function void entropy_src__EXTHT_LO_THRESHOLDS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_THRESH_bit_cg[bt]) this.FIPS_THRESH_bit_cg[bt].sample(FIPS_THRESH.get_mirrored_value() >> bt);
            foreach(BYPASS_THRESH_bit_cg[bt]) this.BYPASS_THRESH_bit_cg[bt].sample(BYPASS_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_THRESH.get_mirrored_value()  ,  BYPASS_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__REPCNT_HI_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__REPCNT_HI_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__REPCNT_HI_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__REPCNTS_HI_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__REPCNTS_HI_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__REPCNTS_HI_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ADAPTP_HI_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ADAPTP_HI_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__ADAPTP_HI_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ADAPTP_LO_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ADAPTP_LO_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__ADAPTP_LO_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__EXTHT_HI_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__EXTHT_HI_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__EXTHT_HI_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__EXTHT_LO_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__EXTHT_LO_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__EXTHT_LO_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__BUCKET_HI_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__BUCKET_HI_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__BUCKET_HI_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__MARKOV_HI_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__MARKOV_HI_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__MARKOV_HI_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__MARKOV_LO_WATERMARKS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__MARKOV_LO_WATERMARKS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(data[0 + bt]);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*FIPS_WATERMARK*/  ,  data[31:16]/*BYPASS_WATERMARK*/   );
        end
    endfunction

    function void entropy_src__MARKOV_LO_WATERMARKS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_WATERMARK_bit_cg[bt]) this.FIPS_WATERMARK_bit_cg[bt].sample(FIPS_WATERMARK.get_mirrored_value() >> bt);
            foreach(BYPASS_WATERMARK_bit_cg[bt]) this.BYPASS_WATERMARK_bit_cg[bt].sample(BYPASS_WATERMARK.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_WATERMARK.get_mirrored_value()  ,  BYPASS_WATERMARK.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__REPCNT_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__REPCNT_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(REPCNT_TOTAL_FAILS_bit_cg[bt]) this.REPCNT_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*REPCNT_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__REPCNT_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(REPCNT_TOTAL_FAILS_bit_cg[bt]) this.REPCNT_TOTAL_FAILS_bit_cg[bt].sample(REPCNT_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( REPCNT_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__REPCNTS_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__REPCNTS_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(REPCNTS_TOTAL_FAILS_bit_cg[bt]) this.REPCNTS_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*REPCNTS_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__REPCNTS_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(REPCNTS_TOTAL_FAILS_bit_cg[bt]) this.REPCNTS_TOTAL_FAILS_bit_cg[bt].sample(REPCNTS_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( REPCNTS_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ADAPTP_HI_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ADAPTP_HI_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ADAPTP_HI_TOTAL_FAILS_bit_cg[bt]) this.ADAPTP_HI_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*ADAPTP_HI_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__ADAPTP_HI_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ADAPTP_HI_TOTAL_FAILS_bit_cg[bt]) this.ADAPTP_HI_TOTAL_FAILS_bit_cg[bt].sample(ADAPTP_HI_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ADAPTP_HI_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ADAPTP_LO_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ADAPTP_LO_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ADAPTP_LO_TOTAL_FAILS_bit_cg[bt]) this.ADAPTP_LO_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*ADAPTP_LO_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__ADAPTP_LO_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ADAPTP_LO_TOTAL_FAILS_bit_cg[bt]) this.ADAPTP_LO_TOTAL_FAILS_bit_cg[bt].sample(ADAPTP_LO_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ADAPTP_LO_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__BUCKET_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__BUCKET_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(BUCKET_TOTAL_FAILS_bit_cg[bt]) this.BUCKET_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*BUCKET_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__BUCKET_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(BUCKET_TOTAL_FAILS_bit_cg[bt]) this.BUCKET_TOTAL_FAILS_bit_cg[bt].sample(BUCKET_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( BUCKET_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__MARKOV_HI_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__MARKOV_HI_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(MARKOV_HI_TOTAL_FAILS_bit_cg[bt]) this.MARKOV_HI_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*MARKOV_HI_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__MARKOV_HI_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(MARKOV_HI_TOTAL_FAILS_bit_cg[bt]) this.MARKOV_HI_TOTAL_FAILS_bit_cg[bt].sample(MARKOV_HI_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( MARKOV_HI_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__MARKOV_LO_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__MARKOV_LO_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(MARKOV_LO_TOTAL_FAILS_bit_cg[bt]) this.MARKOV_LO_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*MARKOV_LO_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__MARKOV_LO_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(MARKOV_LO_TOTAL_FAILS_bit_cg[bt]) this.MARKOV_LO_TOTAL_FAILS_bit_cg[bt].sample(MARKOV_LO_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( MARKOV_LO_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__EXTHT_HI_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__EXTHT_HI_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(EXTHT_HI_TOTAL_FAILS_bit_cg[bt]) this.EXTHT_HI_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*EXTHT_HI_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__EXTHT_HI_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(EXTHT_HI_TOTAL_FAILS_bit_cg[bt]) this.EXTHT_HI_TOTAL_FAILS_bit_cg[bt].sample(EXTHT_HI_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( EXTHT_HI_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__EXTHT_LO_TOTAL_FAILS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__EXTHT_LO_TOTAL_FAILS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(EXTHT_LO_TOTAL_FAILS_bit_cg[bt]) this.EXTHT_LO_TOTAL_FAILS_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*EXTHT_LO_TOTAL_FAILS*/   );
        end
    endfunction

    function void entropy_src__EXTHT_LO_TOTAL_FAILS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(EXTHT_LO_TOTAL_FAILS_bit_cg[bt]) this.EXTHT_LO_TOTAL_FAILS_bit_cg[bt].sample(EXTHT_LO_TOTAL_FAILS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( EXTHT_LO_TOTAL_FAILS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ALERT_THRESHOLD SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ALERT_THRESHOLD::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ALERT_THRESHOLD_bit_cg[bt]) this.ALERT_THRESHOLD_bit_cg[bt].sample(data[0 + bt]);
            foreach(ALERT_THRESHOLD_INV_bit_cg[bt]) this.ALERT_THRESHOLD_INV_bit_cg[bt].sample(data[16 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*ALERT_THRESHOLD*/  ,  data[31:16]/*ALERT_THRESHOLD_INV*/   );
        end
    endfunction

    function void entropy_src__ALERT_THRESHOLD::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ALERT_THRESHOLD_bit_cg[bt]) this.ALERT_THRESHOLD_bit_cg[bt].sample(ALERT_THRESHOLD.get_mirrored_value() >> bt);
            foreach(ALERT_THRESHOLD_INV_bit_cg[bt]) this.ALERT_THRESHOLD_INV_bit_cg[bt].sample(ALERT_THRESHOLD_INV.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ALERT_THRESHOLD.get_mirrored_value()  ,  ALERT_THRESHOLD_INV.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ALERT_SUMMARY_FAIL_COUNTS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ALERT_SUMMARY_FAIL_COUNTS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ANY_FAIL_COUNT_bit_cg[bt]) this.ANY_FAIL_COUNT_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[15:0]/*ANY_FAIL_COUNT*/   );
        end
    endfunction

    function void entropy_src__ALERT_SUMMARY_FAIL_COUNTS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ANY_FAIL_COUNT_bit_cg[bt]) this.ANY_FAIL_COUNT_bit_cg[bt].sample(ANY_FAIL_COUNT.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ANY_FAIL_COUNT.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ALERT_FAIL_COUNTS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ALERT_FAIL_COUNTS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(REPCNT_FAIL_COUNT_bit_cg[bt]) this.REPCNT_FAIL_COUNT_bit_cg[bt].sample(data[4 + bt]);
            foreach(ADAPTP_HI_FAIL_COUNT_bit_cg[bt]) this.ADAPTP_HI_FAIL_COUNT_bit_cg[bt].sample(data[8 + bt]);
            foreach(ADAPTP_LO_FAIL_COUNT_bit_cg[bt]) this.ADAPTP_LO_FAIL_COUNT_bit_cg[bt].sample(data[12 + bt]);
            foreach(BUCKET_FAIL_COUNT_bit_cg[bt]) this.BUCKET_FAIL_COUNT_bit_cg[bt].sample(data[16 + bt]);
            foreach(MARKOV_HI_FAIL_COUNT_bit_cg[bt]) this.MARKOV_HI_FAIL_COUNT_bit_cg[bt].sample(data[20 + bt]);
            foreach(MARKOV_LO_FAIL_COUNT_bit_cg[bt]) this.MARKOV_LO_FAIL_COUNT_bit_cg[bt].sample(data[24 + bt]);
            foreach(REPCNTS_FAIL_COUNT_bit_cg[bt]) this.REPCNTS_FAIL_COUNT_bit_cg[bt].sample(data[28 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[7:4]/*REPCNT_FAIL_COUNT*/  ,  data[11:8]/*ADAPTP_HI_FAIL_COUNT*/  ,  data[15:12]/*ADAPTP_LO_FAIL_COUNT*/  ,  data[19:16]/*BUCKET_FAIL_COUNT*/  ,  data[23:20]/*MARKOV_HI_FAIL_COUNT*/  ,  data[27:24]/*MARKOV_LO_FAIL_COUNT*/  ,  data[31:28]/*REPCNTS_FAIL_COUNT*/   );
        end
    endfunction

    function void entropy_src__ALERT_FAIL_COUNTS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(REPCNT_FAIL_COUNT_bit_cg[bt]) this.REPCNT_FAIL_COUNT_bit_cg[bt].sample(REPCNT_FAIL_COUNT.get_mirrored_value() >> bt);
            foreach(ADAPTP_HI_FAIL_COUNT_bit_cg[bt]) this.ADAPTP_HI_FAIL_COUNT_bit_cg[bt].sample(ADAPTP_HI_FAIL_COUNT.get_mirrored_value() >> bt);
            foreach(ADAPTP_LO_FAIL_COUNT_bit_cg[bt]) this.ADAPTP_LO_FAIL_COUNT_bit_cg[bt].sample(ADAPTP_LO_FAIL_COUNT.get_mirrored_value() >> bt);
            foreach(BUCKET_FAIL_COUNT_bit_cg[bt]) this.BUCKET_FAIL_COUNT_bit_cg[bt].sample(BUCKET_FAIL_COUNT.get_mirrored_value() >> bt);
            foreach(MARKOV_HI_FAIL_COUNT_bit_cg[bt]) this.MARKOV_HI_FAIL_COUNT_bit_cg[bt].sample(MARKOV_HI_FAIL_COUNT.get_mirrored_value() >> bt);
            foreach(MARKOV_LO_FAIL_COUNT_bit_cg[bt]) this.MARKOV_LO_FAIL_COUNT_bit_cg[bt].sample(MARKOV_LO_FAIL_COUNT.get_mirrored_value() >> bt);
            foreach(REPCNTS_FAIL_COUNT_bit_cg[bt]) this.REPCNTS_FAIL_COUNT_bit_cg[bt].sample(REPCNTS_FAIL_COUNT.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( REPCNT_FAIL_COUNT.get_mirrored_value()  ,  ADAPTP_HI_FAIL_COUNT.get_mirrored_value()  ,  ADAPTP_LO_FAIL_COUNT.get_mirrored_value()  ,  BUCKET_FAIL_COUNT.get_mirrored_value()  ,  MARKOV_HI_FAIL_COUNT.get_mirrored_value()  ,  MARKOV_LO_FAIL_COUNT.get_mirrored_value()  ,  REPCNTS_FAIL_COUNT.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__EXTHT_FAIL_COUNTS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__EXTHT_FAIL_COUNTS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(EXTHT_HI_FAIL_COUNT_bit_cg[bt]) this.EXTHT_HI_FAIL_COUNT_bit_cg[bt].sample(data[0 + bt]);
            foreach(EXTHT_LO_FAIL_COUNT_bit_cg[bt]) this.EXTHT_LO_FAIL_COUNT_bit_cg[bt].sample(data[4 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[3:0]/*EXTHT_HI_FAIL_COUNT*/  ,  data[7:4]/*EXTHT_LO_FAIL_COUNT*/   );
        end
    endfunction

    function void entropy_src__EXTHT_FAIL_COUNTS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(EXTHT_HI_FAIL_COUNT_bit_cg[bt]) this.EXTHT_HI_FAIL_COUNT_bit_cg[bt].sample(EXTHT_HI_FAIL_COUNT.get_mirrored_value() >> bt);
            foreach(EXTHT_LO_FAIL_COUNT_bit_cg[bt]) this.EXTHT_LO_FAIL_COUNT_bit_cg[bt].sample(EXTHT_LO_FAIL_COUNT.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( EXTHT_HI_FAIL_COUNT.get_mirrored_value()  ,  EXTHT_LO_FAIL_COUNT.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__FW_OV_CONTROL SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__FW_OV_CONTROL::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_MODE_bit_cg[bt]) this.FW_OV_MODE_bit_cg[bt].sample(data[0 + bt]);
            foreach(FW_OV_ENTROPY_INSERT_bit_cg[bt]) this.FW_OV_ENTROPY_INSERT_bit_cg[bt].sample(data[4 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[3:0]/*FW_OV_MODE*/  ,  data[7:4]/*FW_OV_ENTROPY_INSERT*/   );
        end
    endfunction

    function void entropy_src__FW_OV_CONTROL::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_MODE_bit_cg[bt]) this.FW_OV_MODE_bit_cg[bt].sample(FW_OV_MODE.get_mirrored_value() >> bt);
            foreach(FW_OV_ENTROPY_INSERT_bit_cg[bt]) this.FW_OV_ENTROPY_INSERT_bit_cg[bt].sample(FW_OV_ENTROPY_INSERT.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FW_OV_MODE.get_mirrored_value()  ,  FW_OV_ENTROPY_INSERT.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__FW_OV_SHA3_START SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__FW_OV_SHA3_START::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_INSERT_START_bit_cg[bt]) this.FW_OV_INSERT_START_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[3:0]/*FW_OV_INSERT_START*/   );
        end
    endfunction

    function void entropy_src__FW_OV_SHA3_START::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_INSERT_START_bit_cg[bt]) this.FW_OV_INSERT_START_bit_cg[bt].sample(FW_OV_INSERT_START.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FW_OV_INSERT_START.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__FW_OV_WR_FIFO_FULL SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__FW_OV_WR_FIFO_FULL::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_WR_FIFO_FULL_bit_cg[bt]) this.FW_OV_WR_FIFO_FULL_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*FW_OV_WR_FIFO_FULL*/   );
        end
    endfunction

    function void entropy_src__FW_OV_WR_FIFO_FULL::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_WR_FIFO_FULL_bit_cg[bt]) this.FW_OV_WR_FIFO_FULL_bit_cg[bt].sample(FW_OV_WR_FIFO_FULL.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FW_OV_WR_FIFO_FULL.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__FW_OV_RD_FIFO_OVERFLOW SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__FW_OV_RD_FIFO_OVERFLOW::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_RD_FIFO_OVERFLOW_bit_cg[bt]) this.FW_OV_RD_FIFO_OVERFLOW_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*FW_OV_RD_FIFO_OVERFLOW*/   );
        end
    endfunction

    function void entropy_src__FW_OV_RD_FIFO_OVERFLOW::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_RD_FIFO_OVERFLOW_bit_cg[bt]) this.FW_OV_RD_FIFO_OVERFLOW_bit_cg[bt].sample(FW_OV_RD_FIFO_OVERFLOW.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FW_OV_RD_FIFO_OVERFLOW.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__FW_OV_RD_DATA SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__FW_OV_RD_DATA::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_RD_DATA_bit_cg[bt]) this.FW_OV_RD_DATA_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*FW_OV_RD_DATA*/   );
        end
    endfunction

    function void entropy_src__FW_OV_RD_DATA::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_RD_DATA_bit_cg[bt]) this.FW_OV_RD_DATA_bit_cg[bt].sample(FW_OV_RD_DATA.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FW_OV_RD_DATA.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__FW_OV_WR_DATA SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__FW_OV_WR_DATA::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_WR_DATA_bit_cg[bt]) this.FW_OV_WR_DATA_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*FW_OV_WR_DATA*/   );
        end
    endfunction

    function void entropy_src__FW_OV_WR_DATA::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FW_OV_WR_DATA_bit_cg[bt]) this.FW_OV_WR_DATA_bit_cg[bt].sample(FW_OV_WR_DATA.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FW_OV_WR_DATA.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__OBSERVE_FIFO_THRESH SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__OBSERVE_FIFO_THRESH::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(OBSERVE_FIFO_THRESH_bit_cg[bt]) this.OBSERVE_FIFO_THRESH_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[5:0]/*OBSERVE_FIFO_THRESH*/   );
        end
    endfunction

    function void entropy_src__OBSERVE_FIFO_THRESH::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(OBSERVE_FIFO_THRESH_bit_cg[bt]) this.OBSERVE_FIFO_THRESH_bit_cg[bt].sample(OBSERVE_FIFO_THRESH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( OBSERVE_FIFO_THRESH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__OBSERVE_FIFO_DEPTH SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__OBSERVE_FIFO_DEPTH::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(OBSERVE_FIFO_DEPTH_bit_cg[bt]) this.OBSERVE_FIFO_DEPTH_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[5:0]/*OBSERVE_FIFO_DEPTH*/   );
        end
    endfunction

    function void entropy_src__OBSERVE_FIFO_DEPTH::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(OBSERVE_FIFO_DEPTH_bit_cg[bt]) this.OBSERVE_FIFO_DEPTH_bit_cg[bt].sample(OBSERVE_FIFO_DEPTH.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( OBSERVE_FIFO_DEPTH.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__DEBUG_STATUS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__DEBUG_STATUS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ENTROPY_FIFO_DEPTH_bit_cg[bt]) this.ENTROPY_FIFO_DEPTH_bit_cg[bt].sample(data[0 + bt]);
            foreach(SHA3_FSM_bit_cg[bt]) this.SHA3_FSM_bit_cg[bt].sample(data[3 + bt]);
            foreach(SHA3_BLOCK_PR_bit_cg[bt]) this.SHA3_BLOCK_PR_bit_cg[bt].sample(data[6 + bt]);
            foreach(SHA3_SQUEEZING_bit_cg[bt]) this.SHA3_SQUEEZING_bit_cg[bt].sample(data[7 + bt]);
            foreach(SHA3_ABSORBED_bit_cg[bt]) this.SHA3_ABSORBED_bit_cg[bt].sample(data[8 + bt]);
            foreach(SHA3_ERR_bit_cg[bt]) this.SHA3_ERR_bit_cg[bt].sample(data[9 + bt]);
            foreach(MAIN_SM_IDLE_bit_cg[bt]) this.MAIN_SM_IDLE_bit_cg[bt].sample(data[16 + bt]);
            foreach(MAIN_SM_BOOT_DONE_bit_cg[bt]) this.MAIN_SM_BOOT_DONE_bit_cg[bt].sample(data[17 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[1:0]/*ENTROPY_FIFO_DEPTH*/  ,  data[5:3]/*SHA3_FSM*/  ,  data[6:6]/*SHA3_BLOCK_PR*/  ,  data[7:7]/*SHA3_SQUEEZING*/  ,  data[8:8]/*SHA3_ABSORBED*/  ,  data[9:9]/*SHA3_ERR*/  ,  data[16:16]/*MAIN_SM_IDLE*/  ,  data[17:17]/*MAIN_SM_BOOT_DONE*/   );
        end
    endfunction

    function void entropy_src__DEBUG_STATUS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ENTROPY_FIFO_DEPTH_bit_cg[bt]) this.ENTROPY_FIFO_DEPTH_bit_cg[bt].sample(ENTROPY_FIFO_DEPTH.get_mirrored_value() >> bt);
            foreach(SHA3_FSM_bit_cg[bt]) this.SHA3_FSM_bit_cg[bt].sample(SHA3_FSM.get_mirrored_value() >> bt);
            foreach(SHA3_BLOCK_PR_bit_cg[bt]) this.SHA3_BLOCK_PR_bit_cg[bt].sample(SHA3_BLOCK_PR.get_mirrored_value() >> bt);
            foreach(SHA3_SQUEEZING_bit_cg[bt]) this.SHA3_SQUEEZING_bit_cg[bt].sample(SHA3_SQUEEZING.get_mirrored_value() >> bt);
            foreach(SHA3_ABSORBED_bit_cg[bt]) this.SHA3_ABSORBED_bit_cg[bt].sample(SHA3_ABSORBED.get_mirrored_value() >> bt);
            foreach(SHA3_ERR_bit_cg[bt]) this.SHA3_ERR_bit_cg[bt].sample(SHA3_ERR.get_mirrored_value() >> bt);
            foreach(MAIN_SM_IDLE_bit_cg[bt]) this.MAIN_SM_IDLE_bit_cg[bt].sample(MAIN_SM_IDLE.get_mirrored_value() >> bt);
            foreach(MAIN_SM_BOOT_DONE_bit_cg[bt]) this.MAIN_SM_BOOT_DONE_bit_cg[bt].sample(MAIN_SM_BOOT_DONE.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ENTROPY_FIFO_DEPTH.get_mirrored_value()  ,  SHA3_FSM.get_mirrored_value()  ,  SHA3_BLOCK_PR.get_mirrored_value()  ,  SHA3_SQUEEZING.get_mirrored_value()  ,  SHA3_ABSORBED.get_mirrored_value()  ,  SHA3_ERR.get_mirrored_value()  ,  MAIN_SM_IDLE.get_mirrored_value()  ,  MAIN_SM_BOOT_DONE.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__RECOV_ALERT_STS SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__RECOV_ALERT_STS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_ENABLE_FIELD_ALERT_bit_cg[bt]) this.FIPS_ENABLE_FIELD_ALERT_bit_cg[bt].sample(data[0 + bt]);
            foreach(ENTROPY_DATA_REG_EN_FIELD_ALERT_bit_cg[bt]) this.ENTROPY_DATA_REG_EN_FIELD_ALERT_bit_cg[bt].sample(data[1 + bt]);
            foreach(MODULE_ENABLE_FIELD_ALERT_bit_cg[bt]) this.MODULE_ENABLE_FIELD_ALERT_bit_cg[bt].sample(data[2 + bt]);
            foreach(THRESHOLD_SCOPE_FIELD_ALERT_bit_cg[bt]) this.THRESHOLD_SCOPE_FIELD_ALERT_bit_cg[bt].sample(data[3 + bt]);
            foreach(RNG_BIT_ENABLE_FIELD_ALERT_bit_cg[bt]) this.RNG_BIT_ENABLE_FIELD_ALERT_bit_cg[bt].sample(data[5 + bt]);
            foreach(FW_OV_SHA3_START_FIELD_ALERT_bit_cg[bt]) this.FW_OV_SHA3_START_FIELD_ALERT_bit_cg[bt].sample(data[7 + bt]);
            foreach(FW_OV_MODE_FIELD_ALERT_bit_cg[bt]) this.FW_OV_MODE_FIELD_ALERT_bit_cg[bt].sample(data[8 + bt]);
            foreach(FW_OV_ENTROPY_INSERT_FIELD_ALERT_bit_cg[bt]) this.FW_OV_ENTROPY_INSERT_FIELD_ALERT_bit_cg[bt].sample(data[9 + bt]);
            foreach(ES_ROUTE_FIELD_ALERT_bit_cg[bt]) this.ES_ROUTE_FIELD_ALERT_bit_cg[bt].sample(data[10 + bt]);
            foreach(ES_TYPE_FIELD_ALERT_bit_cg[bt]) this.ES_TYPE_FIELD_ALERT_bit_cg[bt].sample(data[11 + bt]);
            foreach(ES_MAIN_SM_ALERT_bit_cg[bt]) this.ES_MAIN_SM_ALERT_bit_cg[bt].sample(data[12 + bt]);
            foreach(ES_BUS_CMP_ALERT_bit_cg[bt]) this.ES_BUS_CMP_ALERT_bit_cg[bt].sample(data[13 + bt]);
            foreach(ES_THRESH_CFG_ALERT_bit_cg[bt]) this.ES_THRESH_CFG_ALERT_bit_cg[bt].sample(data[14 + bt]);
            foreach(ES_FW_OV_WR_ALERT_bit_cg[bt]) this.ES_FW_OV_WR_ALERT_bit_cg[bt].sample(data[15 + bt]);
            foreach(ES_FW_OV_DISABLE_ALERT_bit_cg[bt]) this.ES_FW_OV_DISABLE_ALERT_bit_cg[bt].sample(data[16 + bt]);
            foreach(FIPS_FLAG_FIELD_ALERT_bit_cg[bt]) this.FIPS_FLAG_FIELD_ALERT_bit_cg[bt].sample(data[17 + bt]);
            foreach(RNG_FIPS_FIELD_ALERT_bit_cg[bt]) this.RNG_FIPS_FIELD_ALERT_bit_cg[bt].sample(data[18 + bt]);
            foreach(POSTHT_ENTROPY_DROP_ALERT_bit_cg[bt]) this.POSTHT_ENTROPY_DROP_ALERT_bit_cg[bt].sample(data[31 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*FIPS_ENABLE_FIELD_ALERT*/  ,  data[1:1]/*ENTROPY_DATA_REG_EN_FIELD_ALERT*/  ,  data[2:2]/*MODULE_ENABLE_FIELD_ALERT*/  ,  data[3:3]/*THRESHOLD_SCOPE_FIELD_ALERT*/  ,  data[5:5]/*RNG_BIT_ENABLE_FIELD_ALERT*/  ,  data[7:7]/*FW_OV_SHA3_START_FIELD_ALERT*/  ,  data[8:8]/*FW_OV_MODE_FIELD_ALERT*/  ,  data[9:9]/*FW_OV_ENTROPY_INSERT_FIELD_ALERT*/  ,  data[10:10]/*ES_ROUTE_FIELD_ALERT*/  ,  data[11:11]/*ES_TYPE_FIELD_ALERT*/  ,  data[12:12]/*ES_MAIN_SM_ALERT*/  ,  data[13:13]/*ES_BUS_CMP_ALERT*/  ,  data[14:14]/*ES_THRESH_CFG_ALERT*/  ,  data[15:15]/*ES_FW_OV_WR_ALERT*/  ,  data[16:16]/*ES_FW_OV_DISABLE_ALERT*/  ,  data[17:17]/*FIPS_FLAG_FIELD_ALERT*/  ,  data[18:18]/*RNG_FIPS_FIELD_ALERT*/  ,  data[31:31]/*POSTHT_ENTROPY_DROP_ALERT*/   );
        end
    endfunction

    function void entropy_src__RECOV_ALERT_STS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(FIPS_ENABLE_FIELD_ALERT_bit_cg[bt]) this.FIPS_ENABLE_FIELD_ALERT_bit_cg[bt].sample(FIPS_ENABLE_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(ENTROPY_DATA_REG_EN_FIELD_ALERT_bit_cg[bt]) this.ENTROPY_DATA_REG_EN_FIELD_ALERT_bit_cg[bt].sample(ENTROPY_DATA_REG_EN_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(MODULE_ENABLE_FIELD_ALERT_bit_cg[bt]) this.MODULE_ENABLE_FIELD_ALERT_bit_cg[bt].sample(MODULE_ENABLE_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(THRESHOLD_SCOPE_FIELD_ALERT_bit_cg[bt]) this.THRESHOLD_SCOPE_FIELD_ALERT_bit_cg[bt].sample(THRESHOLD_SCOPE_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(RNG_BIT_ENABLE_FIELD_ALERT_bit_cg[bt]) this.RNG_BIT_ENABLE_FIELD_ALERT_bit_cg[bt].sample(RNG_BIT_ENABLE_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(FW_OV_SHA3_START_FIELD_ALERT_bit_cg[bt]) this.FW_OV_SHA3_START_FIELD_ALERT_bit_cg[bt].sample(FW_OV_SHA3_START_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(FW_OV_MODE_FIELD_ALERT_bit_cg[bt]) this.FW_OV_MODE_FIELD_ALERT_bit_cg[bt].sample(FW_OV_MODE_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(FW_OV_ENTROPY_INSERT_FIELD_ALERT_bit_cg[bt]) this.FW_OV_ENTROPY_INSERT_FIELD_ALERT_bit_cg[bt].sample(FW_OV_ENTROPY_INSERT_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(ES_ROUTE_FIELD_ALERT_bit_cg[bt]) this.ES_ROUTE_FIELD_ALERT_bit_cg[bt].sample(ES_ROUTE_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(ES_TYPE_FIELD_ALERT_bit_cg[bt]) this.ES_TYPE_FIELD_ALERT_bit_cg[bt].sample(ES_TYPE_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(ES_MAIN_SM_ALERT_bit_cg[bt]) this.ES_MAIN_SM_ALERT_bit_cg[bt].sample(ES_MAIN_SM_ALERT.get_mirrored_value() >> bt);
            foreach(ES_BUS_CMP_ALERT_bit_cg[bt]) this.ES_BUS_CMP_ALERT_bit_cg[bt].sample(ES_BUS_CMP_ALERT.get_mirrored_value() >> bt);
            foreach(ES_THRESH_CFG_ALERT_bit_cg[bt]) this.ES_THRESH_CFG_ALERT_bit_cg[bt].sample(ES_THRESH_CFG_ALERT.get_mirrored_value() >> bt);
            foreach(ES_FW_OV_WR_ALERT_bit_cg[bt]) this.ES_FW_OV_WR_ALERT_bit_cg[bt].sample(ES_FW_OV_WR_ALERT.get_mirrored_value() >> bt);
            foreach(ES_FW_OV_DISABLE_ALERT_bit_cg[bt]) this.ES_FW_OV_DISABLE_ALERT_bit_cg[bt].sample(ES_FW_OV_DISABLE_ALERT.get_mirrored_value() >> bt);
            foreach(FIPS_FLAG_FIELD_ALERT_bit_cg[bt]) this.FIPS_FLAG_FIELD_ALERT_bit_cg[bt].sample(FIPS_FLAG_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(RNG_FIPS_FIELD_ALERT_bit_cg[bt]) this.RNG_FIPS_FIELD_ALERT_bit_cg[bt].sample(RNG_FIPS_FIELD_ALERT.get_mirrored_value() >> bt);
            foreach(POSTHT_ENTROPY_DROP_ALERT_bit_cg[bt]) this.POSTHT_ENTROPY_DROP_ALERT_bit_cg[bt].sample(POSTHT_ENTROPY_DROP_ALERT.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( FIPS_ENABLE_FIELD_ALERT.get_mirrored_value()  ,  ENTROPY_DATA_REG_EN_FIELD_ALERT.get_mirrored_value()  ,  MODULE_ENABLE_FIELD_ALERT.get_mirrored_value()  ,  THRESHOLD_SCOPE_FIELD_ALERT.get_mirrored_value()  ,  RNG_BIT_ENABLE_FIELD_ALERT.get_mirrored_value()  ,  FW_OV_SHA3_START_FIELD_ALERT.get_mirrored_value()  ,  FW_OV_MODE_FIELD_ALERT.get_mirrored_value()  ,  FW_OV_ENTROPY_INSERT_FIELD_ALERT.get_mirrored_value()  ,  ES_ROUTE_FIELD_ALERT.get_mirrored_value()  ,  ES_TYPE_FIELD_ALERT.get_mirrored_value()  ,  ES_MAIN_SM_ALERT.get_mirrored_value()  ,  ES_BUS_CMP_ALERT.get_mirrored_value()  ,  ES_THRESH_CFG_ALERT.get_mirrored_value()  ,  ES_FW_OV_WR_ALERT.get_mirrored_value()  ,  ES_FW_OV_DISABLE_ALERT.get_mirrored_value()  ,  FIPS_FLAG_FIELD_ALERT.get_mirrored_value()  ,  RNG_FIPS_FIELD_ALERT.get_mirrored_value()  ,  POSTHT_ENTROPY_DROP_ALERT.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ERR_CODE SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ERR_CODE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(SFIFO_ESRNG_ERR_bit_cg[bt]) this.SFIFO_ESRNG_ERR_bit_cg[bt].sample(data[0 + bt]);
            foreach(SFIFO_DISTR_ERR_bit_cg[bt]) this.SFIFO_DISTR_ERR_bit_cg[bt].sample(data[1 + bt]);
            foreach(SFIFO_OBSERVE_ERR_bit_cg[bt]) this.SFIFO_OBSERVE_ERR_bit_cg[bt].sample(data[2 + bt]);
            foreach(SFIFO_ESFINAL_ERR_bit_cg[bt]) this.SFIFO_ESFINAL_ERR_bit_cg[bt].sample(data[3 + bt]);
            foreach(ES_ACK_SM_ERR_bit_cg[bt]) this.ES_ACK_SM_ERR_bit_cg[bt].sample(data[20 + bt]);
            foreach(ES_MAIN_SM_ERR_bit_cg[bt]) this.ES_MAIN_SM_ERR_bit_cg[bt].sample(data[21 + bt]);
            foreach(ES_CNTR_ERR_bit_cg[bt]) this.ES_CNTR_ERR_bit_cg[bt].sample(data[22 + bt]);
            foreach(SHA3_STATE_ERR_bit_cg[bt]) this.SHA3_STATE_ERR_bit_cg[bt].sample(data[23 + bt]);
            foreach(SHA3_RST_STORAGE_ERR_bit_cg[bt]) this.SHA3_RST_STORAGE_ERR_bit_cg[bt].sample(data[24 + bt]);
            foreach(FIFO_WRITE_ERR_bit_cg[bt]) this.FIFO_WRITE_ERR_bit_cg[bt].sample(data[28 + bt]);
            foreach(FIFO_READ_ERR_bit_cg[bt]) this.FIFO_READ_ERR_bit_cg[bt].sample(data[29 + bt]);
            foreach(FIFO_STATE_ERR_bit_cg[bt]) this.FIFO_STATE_ERR_bit_cg[bt].sample(data[30 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*SFIFO_ESRNG_ERR*/  ,  data[1:1]/*SFIFO_DISTR_ERR*/  ,  data[2:2]/*SFIFO_OBSERVE_ERR*/  ,  data[3:3]/*SFIFO_ESFINAL_ERR*/  ,  data[20:20]/*ES_ACK_SM_ERR*/  ,  data[21:21]/*ES_MAIN_SM_ERR*/  ,  data[22:22]/*ES_CNTR_ERR*/  ,  data[23:23]/*SHA3_STATE_ERR*/  ,  data[24:24]/*SHA3_RST_STORAGE_ERR*/  ,  data[28:28]/*FIFO_WRITE_ERR*/  ,  data[29:29]/*FIFO_READ_ERR*/  ,  data[30:30]/*FIFO_STATE_ERR*/   );
        end
    endfunction

    function void entropy_src__ERR_CODE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(SFIFO_ESRNG_ERR_bit_cg[bt]) this.SFIFO_ESRNG_ERR_bit_cg[bt].sample(SFIFO_ESRNG_ERR.get_mirrored_value() >> bt);
            foreach(SFIFO_DISTR_ERR_bit_cg[bt]) this.SFIFO_DISTR_ERR_bit_cg[bt].sample(SFIFO_DISTR_ERR.get_mirrored_value() >> bt);
            foreach(SFIFO_OBSERVE_ERR_bit_cg[bt]) this.SFIFO_OBSERVE_ERR_bit_cg[bt].sample(SFIFO_OBSERVE_ERR.get_mirrored_value() >> bt);
            foreach(SFIFO_ESFINAL_ERR_bit_cg[bt]) this.SFIFO_ESFINAL_ERR_bit_cg[bt].sample(SFIFO_ESFINAL_ERR.get_mirrored_value() >> bt);
            foreach(ES_ACK_SM_ERR_bit_cg[bt]) this.ES_ACK_SM_ERR_bit_cg[bt].sample(ES_ACK_SM_ERR.get_mirrored_value() >> bt);
            foreach(ES_MAIN_SM_ERR_bit_cg[bt]) this.ES_MAIN_SM_ERR_bit_cg[bt].sample(ES_MAIN_SM_ERR.get_mirrored_value() >> bt);
            foreach(ES_CNTR_ERR_bit_cg[bt]) this.ES_CNTR_ERR_bit_cg[bt].sample(ES_CNTR_ERR.get_mirrored_value() >> bt);
            foreach(SHA3_STATE_ERR_bit_cg[bt]) this.SHA3_STATE_ERR_bit_cg[bt].sample(SHA3_STATE_ERR.get_mirrored_value() >> bt);
            foreach(SHA3_RST_STORAGE_ERR_bit_cg[bt]) this.SHA3_RST_STORAGE_ERR_bit_cg[bt].sample(SHA3_RST_STORAGE_ERR.get_mirrored_value() >> bt);
            foreach(FIFO_WRITE_ERR_bit_cg[bt]) this.FIFO_WRITE_ERR_bit_cg[bt].sample(FIFO_WRITE_ERR.get_mirrored_value() >> bt);
            foreach(FIFO_READ_ERR_bit_cg[bt]) this.FIFO_READ_ERR_bit_cg[bt].sample(FIFO_READ_ERR.get_mirrored_value() >> bt);
            foreach(FIFO_STATE_ERR_bit_cg[bt]) this.FIFO_STATE_ERR_bit_cg[bt].sample(FIFO_STATE_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( SFIFO_ESRNG_ERR.get_mirrored_value()  ,  SFIFO_DISTR_ERR.get_mirrored_value()  ,  SFIFO_OBSERVE_ERR.get_mirrored_value()  ,  SFIFO_ESFINAL_ERR.get_mirrored_value()  ,  ES_ACK_SM_ERR.get_mirrored_value()  ,  ES_MAIN_SM_ERR.get_mirrored_value()  ,  ES_CNTR_ERR.get_mirrored_value()  ,  SHA3_STATE_ERR.get_mirrored_value()  ,  SHA3_RST_STORAGE_ERR.get_mirrored_value()  ,  FIFO_WRITE_ERR.get_mirrored_value()  ,  FIFO_READ_ERR.get_mirrored_value()  ,  FIFO_STATE_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__ERR_CODE_TEST SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__ERR_CODE_TEST::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ERR_CODE_TEST_bit_cg[bt]) this.ERR_CODE_TEST_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[4:0]/*ERR_CODE_TEST*/   );
        end
    endfunction

    function void entropy_src__ERR_CODE_TEST::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ERR_CODE_TEST_bit_cg[bt]) this.ERR_CODE_TEST_bit_cg[bt].sample(ERR_CODE_TEST.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ERR_CODE_TEST.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- ENTROPY_SRC__MAIN_SM_STATE SAMPLE FUNCTIONS -----------------------*/
    function void entropy_src__MAIN_SM_STATE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(MAIN_SM_STATE_bit_cg[bt]) this.MAIN_SM_STATE_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[8:0]/*MAIN_SM_STATE*/   );
        end
    endfunction

    function void entropy_src__MAIN_SM_STATE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(MAIN_SM_STATE_bit_cg[bt]) this.MAIN_SM_STATE_bit_cg[bt].sample(MAIN_SM_STATE.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( MAIN_SM_STATE.get_mirrored_value()   );
        end
    endfunction

`endif