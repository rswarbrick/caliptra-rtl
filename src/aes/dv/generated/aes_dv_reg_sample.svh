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

`ifndef AES_DV_REG_SAMPLE
    `define AES_DV_REG_SAMPLE
    
    /*----------------------- AES__KEY_SHARE0 SAMPLE FUNCTIONS -----------------------*/
    function void aes__KEY_SHARE0::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KEY_SHARE0_bit_cg[bt]) this.KEY_SHARE0_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*KEY_SHARE0*/   );
        end
    endfunction

    function void aes__KEY_SHARE0::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KEY_SHARE0_bit_cg[bt]) this.KEY_SHARE0_bit_cg[bt].sample(KEY_SHARE0.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( KEY_SHARE0.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__KEY_SHARE1 SAMPLE FUNCTIONS -----------------------*/
    function void aes__KEY_SHARE1::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KEY_SHARE1_bit_cg[bt]) this.KEY_SHARE1_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*KEY_SHARE1*/   );
        end
    endfunction

    function void aes__KEY_SHARE1::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KEY_SHARE1_bit_cg[bt]) this.KEY_SHARE1_bit_cg[bt].sample(KEY_SHARE1.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( KEY_SHARE1.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__IV SAMPLE FUNCTIONS -----------------------*/
    function void aes__IV::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(IV_bit_cg[bt]) this.IV_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*IV*/   );
        end
    endfunction

    function void aes__IV::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(IV_bit_cg[bt]) this.IV_bit_cg[bt].sample(IV.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( IV.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__DATA_IN SAMPLE FUNCTIONS -----------------------*/
    function void aes__DATA_IN::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(DATA_IN_bit_cg[bt]) this.DATA_IN_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*DATA_IN*/   );
        end
    endfunction

    function void aes__DATA_IN::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(DATA_IN_bit_cg[bt]) this.DATA_IN_bit_cg[bt].sample(DATA_IN.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( DATA_IN.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__DATA_OUT SAMPLE FUNCTIONS -----------------------*/
    function void aes__DATA_OUT::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(DATA_OUT_bit_cg[bt]) this.DATA_OUT_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*DATA_OUT*/   );
        end
    endfunction

    function void aes__DATA_OUT::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(DATA_OUT_bit_cg[bt]) this.DATA_OUT_bit_cg[bt].sample(DATA_OUT.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( DATA_OUT.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__CTRL_SHADOWED SAMPLE FUNCTIONS -----------------------*/
    function void aes__CTRL_SHADOWED::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(OPERATION_bit_cg[bt]) this.OPERATION_bit_cg[bt].sample(data[0 + bt]);
            foreach(MODE_bit_cg[bt]) this.MODE_bit_cg[bt].sample(data[2 + bt]);
            foreach(KEY_LEN_bit_cg[bt]) this.KEY_LEN_bit_cg[bt].sample(data[8 + bt]);
            foreach(SIDELOAD_bit_cg[bt]) this.SIDELOAD_bit_cg[bt].sample(data[11 + bt]);
            foreach(PRNG_RESEED_RATE_bit_cg[bt]) this.PRNG_RESEED_RATE_bit_cg[bt].sample(data[12 + bt]);
            foreach(MANUAL_OPERATION_bit_cg[bt]) this.MANUAL_OPERATION_bit_cg[bt].sample(data[15 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[1:0]/*OPERATION*/  ,  data[7:2]/*MODE*/  ,  data[10:8]/*KEY_LEN*/  ,  data[11:11]/*SIDELOAD*/  ,  data[14:12]/*PRNG_RESEED_RATE*/  ,  data[15:15]/*MANUAL_OPERATION*/   );
        end
    endfunction

    function void aes__CTRL_SHADOWED::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(OPERATION_bit_cg[bt]) this.OPERATION_bit_cg[bt].sample(OPERATION.get_mirrored_value() >> bt);
            foreach(MODE_bit_cg[bt]) this.MODE_bit_cg[bt].sample(MODE.get_mirrored_value() >> bt);
            foreach(KEY_LEN_bit_cg[bt]) this.KEY_LEN_bit_cg[bt].sample(KEY_LEN.get_mirrored_value() >> bt);
            foreach(SIDELOAD_bit_cg[bt]) this.SIDELOAD_bit_cg[bt].sample(SIDELOAD.get_mirrored_value() >> bt);
            foreach(PRNG_RESEED_RATE_bit_cg[bt]) this.PRNG_RESEED_RATE_bit_cg[bt].sample(PRNG_RESEED_RATE.get_mirrored_value() >> bt);
            foreach(MANUAL_OPERATION_bit_cg[bt]) this.MANUAL_OPERATION_bit_cg[bt].sample(MANUAL_OPERATION.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( OPERATION.get_mirrored_value()  ,  MODE.get_mirrored_value()  ,  KEY_LEN.get_mirrored_value()  ,  SIDELOAD.get_mirrored_value()  ,  PRNG_RESEED_RATE.get_mirrored_value()  ,  MANUAL_OPERATION.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__CTRL_AUX_SHADOWED SAMPLE FUNCTIONS -----------------------*/
    function void aes__CTRL_AUX_SHADOWED::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KEY_TOUCH_FORCES_RESEED_bit_cg[bt]) this.KEY_TOUCH_FORCES_RESEED_bit_cg[bt].sample(data[0 + bt]);
            foreach(FORCE_MASKS_bit_cg[bt]) this.FORCE_MASKS_bit_cg[bt].sample(data[1 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*KEY_TOUCH_FORCES_RESEED*/  ,  data[1:1]/*FORCE_MASKS*/   );
        end
    endfunction

    function void aes__CTRL_AUX_SHADOWED::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KEY_TOUCH_FORCES_RESEED_bit_cg[bt]) this.KEY_TOUCH_FORCES_RESEED_bit_cg[bt].sample(KEY_TOUCH_FORCES_RESEED.get_mirrored_value() >> bt);
            foreach(FORCE_MASKS_bit_cg[bt]) this.FORCE_MASKS_bit_cg[bt].sample(FORCE_MASKS.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( KEY_TOUCH_FORCES_RESEED.get_mirrored_value()  ,  FORCE_MASKS.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__CTRL_AUX_REGWEN SAMPLE FUNCTIONS -----------------------*/
    function void aes__CTRL_AUX_REGWEN::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(CTRL_AUX_REGWEN_bit_cg[bt]) this.CTRL_AUX_REGWEN_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*CTRL_AUX_REGWEN*/   );
        end
    endfunction

    function void aes__CTRL_AUX_REGWEN::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(CTRL_AUX_REGWEN_bit_cg[bt]) this.CTRL_AUX_REGWEN_bit_cg[bt].sample(CTRL_AUX_REGWEN.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( CTRL_AUX_REGWEN.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__TRIGGER SAMPLE FUNCTIONS -----------------------*/
    function void aes__TRIGGER::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(START_bit_cg[bt]) this.START_bit_cg[bt].sample(data[0 + bt]);
            foreach(KEY_IV_DATA_IN_CLEAR_bit_cg[bt]) this.KEY_IV_DATA_IN_CLEAR_bit_cg[bt].sample(data[1 + bt]);
            foreach(DATA_OUT_CLEAR_bit_cg[bt]) this.DATA_OUT_CLEAR_bit_cg[bt].sample(data[2 + bt]);
            foreach(PRNG_RESEED_bit_cg[bt]) this.PRNG_RESEED_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*START*/  ,  data[1:1]/*KEY_IV_DATA_IN_CLEAR*/  ,  data[2:2]/*DATA_OUT_CLEAR*/  ,  data[3:3]/*PRNG_RESEED*/   );
        end
    endfunction

    function void aes__TRIGGER::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(START_bit_cg[bt]) this.START_bit_cg[bt].sample(START.get_mirrored_value() >> bt);
            foreach(KEY_IV_DATA_IN_CLEAR_bit_cg[bt]) this.KEY_IV_DATA_IN_CLEAR_bit_cg[bt].sample(KEY_IV_DATA_IN_CLEAR.get_mirrored_value() >> bt);
            foreach(DATA_OUT_CLEAR_bit_cg[bt]) this.DATA_OUT_CLEAR_bit_cg[bt].sample(DATA_OUT_CLEAR.get_mirrored_value() >> bt);
            foreach(PRNG_RESEED_bit_cg[bt]) this.PRNG_RESEED_bit_cg[bt].sample(PRNG_RESEED.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( START.get_mirrored_value()  ,  KEY_IV_DATA_IN_CLEAR.get_mirrored_value()  ,  DATA_OUT_CLEAR.get_mirrored_value()  ,  PRNG_RESEED.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__STATUS SAMPLE FUNCTIONS -----------------------*/
    function void aes__STATUS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(IDLE_bit_cg[bt]) this.IDLE_bit_cg[bt].sample(data[0 + bt]);
            foreach(STALL_bit_cg[bt]) this.STALL_bit_cg[bt].sample(data[1 + bt]);
            foreach(OUTPUT_LOST_bit_cg[bt]) this.OUTPUT_LOST_bit_cg[bt].sample(data[2 + bt]);
            foreach(OUTPUT_VALID_bit_cg[bt]) this.OUTPUT_VALID_bit_cg[bt].sample(data[3 + bt]);
            foreach(INPUT_READY_bit_cg[bt]) this.INPUT_READY_bit_cg[bt].sample(data[4 + bt]);
            foreach(ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt]) this.ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt].sample(data[5 + bt]);
            foreach(ALERT_FATAL_FAULT_bit_cg[bt]) this.ALERT_FATAL_FAULT_bit_cg[bt].sample(data[6 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*IDLE*/  ,  data[1:1]/*STALL*/  ,  data[2:2]/*OUTPUT_LOST*/  ,  data[3:3]/*OUTPUT_VALID*/  ,  data[4:4]/*INPUT_READY*/  ,  data[5:5]/*ALERT_RECOV_CTRL_UPDATE_ERR*/  ,  data[6:6]/*ALERT_FATAL_FAULT*/   );
        end
    endfunction

    function void aes__STATUS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(IDLE_bit_cg[bt]) this.IDLE_bit_cg[bt].sample(IDLE.get_mirrored_value() >> bt);
            foreach(STALL_bit_cg[bt]) this.STALL_bit_cg[bt].sample(STALL.get_mirrored_value() >> bt);
            foreach(OUTPUT_LOST_bit_cg[bt]) this.OUTPUT_LOST_bit_cg[bt].sample(OUTPUT_LOST.get_mirrored_value() >> bt);
            foreach(OUTPUT_VALID_bit_cg[bt]) this.OUTPUT_VALID_bit_cg[bt].sample(OUTPUT_VALID.get_mirrored_value() >> bt);
            foreach(INPUT_READY_bit_cg[bt]) this.INPUT_READY_bit_cg[bt].sample(INPUT_READY.get_mirrored_value() >> bt);
            foreach(ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt]) this.ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt].sample(ALERT_RECOV_CTRL_UPDATE_ERR.get_mirrored_value() >> bt);
            foreach(ALERT_FATAL_FAULT_bit_cg[bt]) this.ALERT_FATAL_FAULT_bit_cg[bt].sample(ALERT_FATAL_FAULT.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( IDLE.get_mirrored_value()  ,  STALL.get_mirrored_value()  ,  OUTPUT_LOST.get_mirrored_value()  ,  OUTPUT_VALID.get_mirrored_value()  ,  INPUT_READY.get_mirrored_value()  ,  ALERT_RECOV_CTRL_UPDATE_ERR.get_mirrored_value()  ,  ALERT_FATAL_FAULT.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES__CTRL_GCM_SHADOWED SAMPLE FUNCTIONS -----------------------*/
    function void aes__CTRL_GCM_SHADOWED::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PHASE_bit_cg[bt]) this.PHASE_bit_cg[bt].sample(data[0 + bt]);
            foreach(NUM_VALID_BYTES_bit_cg[bt]) this.NUM_VALID_BYTES_bit_cg[bt].sample(data[6 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[5:0]/*PHASE*/  ,  data[10:6]/*NUM_VALID_BYTES*/   );
        end
    endfunction

    function void aes__CTRL_GCM_SHADOWED::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PHASE_bit_cg[bt]) this.PHASE_bit_cg[bt].sample(PHASE.get_mirrored_value() >> bt);
            foreach(NUM_VALID_BYTES_bit_cg[bt]) this.NUM_VALID_BYTES_bit_cg[bt].sample(NUM_VALID_BYTES.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PHASE.get_mirrored_value()  ,  NUM_VALID_BYTES.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__AES_NAME SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__AES_NAME::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(NAME_bit_cg[bt]) this.NAME_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*NAME*/   );
        end
    endfunction

    function void aes_clp_reg__AES_NAME::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(NAME_bit_cg[bt]) this.NAME_bit_cg[bt].sample(NAME.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( NAME.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__AES_VERSION SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__AES_VERSION::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(VERSION_bit_cg[bt]) this.VERSION_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*VERSION*/   );
        end
    endfunction

    function void aes_clp_reg__AES_VERSION::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(VERSION_bit_cg[bt]) this.VERSION_bit_cg[bt].sample(VERSION.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( VERSION.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__ENTROPY_IF_SEED SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__ENTROPY_IF_SEED::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ENTROPY_IF_SEED_bit_cg[bt]) this.ENTROPY_IF_SEED_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*ENTROPY_IF_SEED*/   );
        end
    endfunction

    function void aes_clp_reg__ENTROPY_IF_SEED::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ENTROPY_IF_SEED_bit_cg[bt]) this.ENTROPY_IF_SEED_bit_cg[bt].sample(ENTROPY_IF_SEED.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ENTROPY_IF_SEED.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__CTRL0 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__CTRL0::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ENDIAN_SWAP_bit_cg[bt]) this.ENDIAN_SWAP_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*ENDIAN_SWAP*/   );
        end
    endfunction

    function void aes_clp_reg__CTRL0::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ENDIAN_SWAP_bit_cg[bt]) this.ENDIAN_SWAP_bit_cg[bt].sample(ENDIAN_SWAP.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ENDIAN_SWAP.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KV_READ_CTRL_REG SAMPLE FUNCTIONS -----------------------*/
    function void kv_read_ctrl_reg::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(read_en_bit_cg[bt]) this.read_en_bit_cg[bt].sample(data[0 + bt]);
            foreach(read_entry_bit_cg[bt]) this.read_entry_bit_cg[bt].sample(data[1 + bt]);
            foreach(pcr_hash_extend_bit_cg[bt]) this.pcr_hash_extend_bit_cg[bt].sample(data[6 + bt]);
            foreach(rsvd_bit_cg[bt]) this.rsvd_bit_cg[bt].sample(data[7 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*read_en*/  ,  data[5:1]/*read_entry*/  ,  data[6:6]/*pcr_hash_extend*/  ,  data[31:7]/*rsvd*/   );
        end
    endfunction

    function void kv_read_ctrl_reg::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(read_en_bit_cg[bt]) this.read_en_bit_cg[bt].sample(read_en.get_mirrored_value() >> bt);
            foreach(read_entry_bit_cg[bt]) this.read_entry_bit_cg[bt].sample(read_entry.get_mirrored_value() >> bt);
            foreach(pcr_hash_extend_bit_cg[bt]) this.pcr_hash_extend_bit_cg[bt].sample(pcr_hash_extend.get_mirrored_value() >> bt);
            foreach(rsvd_bit_cg[bt]) this.rsvd_bit_cg[bt].sample(rsvd.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( read_en.get_mirrored_value()  ,  read_entry.get_mirrored_value()  ,  pcr_hash_extend.get_mirrored_value()  ,  rsvd.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KV_STATUS_REG SAMPLE FUNCTIONS -----------------------*/
    function void kv_status_reg::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(READY_bit_cg[bt]) this.READY_bit_cg[bt].sample(data[0 + bt]);
            foreach(VALID_bit_cg[bt]) this.VALID_bit_cg[bt].sample(data[1 + bt]);
            foreach(ERROR_bit_cg[bt]) this.ERROR_bit_cg[bt].sample(data[2 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*READY*/  ,  data[1:1]/*VALID*/  ,  data[9:2]/*ERROR*/   );
        end
    endfunction

    function void kv_status_reg::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(READY_bit_cg[bt]) this.READY_bit_cg[bt].sample(READY.get_mirrored_value() >> bt);
            foreach(VALID_bit_cg[bt]) this.VALID_bit_cg[bt].sample(VALID.get_mirrored_value() >> bt);
            foreach(ERROR_bit_cg[bt]) this.ERROR_bit_cg[bt].sample(ERROR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( READY.get_mirrored_value()  ,  VALID.get_mirrored_value()  ,  ERROR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KV_WRITE_CTRL_REG SAMPLE FUNCTIONS -----------------------*/
    function void kv_write_ctrl_reg::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(write_en_bit_cg[bt]) this.write_en_bit_cg[bt].sample(data[0 + bt]);
            foreach(write_entry_bit_cg[bt]) this.write_entry_bit_cg[bt].sample(data[1 + bt]);
            foreach(hmac_key_dest_valid_bit_cg[bt]) this.hmac_key_dest_valid_bit_cg[bt].sample(data[6 + bt]);
            foreach(hmac_block_dest_valid_bit_cg[bt]) this.hmac_block_dest_valid_bit_cg[bt].sample(data[7 + bt]);
            foreach(mldsa_seed_dest_valid_bit_cg[bt]) this.mldsa_seed_dest_valid_bit_cg[bt].sample(data[8 + bt]);
            foreach(ecc_pkey_dest_valid_bit_cg[bt]) this.ecc_pkey_dest_valid_bit_cg[bt].sample(data[9 + bt]);
            foreach(ecc_seed_dest_valid_bit_cg[bt]) this.ecc_seed_dest_valid_bit_cg[bt].sample(data[10 + bt]);
            foreach(aes_key_dest_valid_bit_cg[bt]) this.aes_key_dest_valid_bit_cg[bt].sample(data[11 + bt]);
            foreach(mlkem_seed_dest_valid_bit_cg[bt]) this.mlkem_seed_dest_valid_bit_cg[bt].sample(data[12 + bt]);
            foreach(mlkem_msg_dest_valid_bit_cg[bt]) this.mlkem_msg_dest_valid_bit_cg[bt].sample(data[13 + bt]);
            foreach(dma_data_dest_valid_bit_cg[bt]) this.dma_data_dest_valid_bit_cg[bt].sample(data[14 + bt]);
            foreach(rsvd_bit_cg[bt]) this.rsvd_bit_cg[bt].sample(data[15 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*write_en*/  ,  data[5:1]/*write_entry*/  ,  data[6:6]/*hmac_key_dest_valid*/  ,  data[7:7]/*hmac_block_dest_valid*/  ,  data[8:8]/*mldsa_seed_dest_valid*/  ,  data[9:9]/*ecc_pkey_dest_valid*/  ,  data[10:10]/*ecc_seed_dest_valid*/  ,  data[11:11]/*aes_key_dest_valid*/  ,  data[12:12]/*mlkem_seed_dest_valid*/  ,  data[13:13]/*mlkem_msg_dest_valid*/  ,  data[14:14]/*dma_data_dest_valid*/  ,  data[31:15]/*rsvd*/   );
        end
    endfunction

    function void kv_write_ctrl_reg::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(write_en_bit_cg[bt]) this.write_en_bit_cg[bt].sample(write_en.get_mirrored_value() >> bt);
            foreach(write_entry_bit_cg[bt]) this.write_entry_bit_cg[bt].sample(write_entry.get_mirrored_value() >> bt);
            foreach(hmac_key_dest_valid_bit_cg[bt]) this.hmac_key_dest_valid_bit_cg[bt].sample(hmac_key_dest_valid.get_mirrored_value() >> bt);
            foreach(hmac_block_dest_valid_bit_cg[bt]) this.hmac_block_dest_valid_bit_cg[bt].sample(hmac_block_dest_valid.get_mirrored_value() >> bt);
            foreach(mldsa_seed_dest_valid_bit_cg[bt]) this.mldsa_seed_dest_valid_bit_cg[bt].sample(mldsa_seed_dest_valid.get_mirrored_value() >> bt);
            foreach(ecc_pkey_dest_valid_bit_cg[bt]) this.ecc_pkey_dest_valid_bit_cg[bt].sample(ecc_pkey_dest_valid.get_mirrored_value() >> bt);
            foreach(ecc_seed_dest_valid_bit_cg[bt]) this.ecc_seed_dest_valid_bit_cg[bt].sample(ecc_seed_dest_valid.get_mirrored_value() >> bt);
            foreach(aes_key_dest_valid_bit_cg[bt]) this.aes_key_dest_valid_bit_cg[bt].sample(aes_key_dest_valid.get_mirrored_value() >> bt);
            foreach(mlkem_seed_dest_valid_bit_cg[bt]) this.mlkem_seed_dest_valid_bit_cg[bt].sample(mlkem_seed_dest_valid.get_mirrored_value() >> bt);
            foreach(mlkem_msg_dest_valid_bit_cg[bt]) this.mlkem_msg_dest_valid_bit_cg[bt].sample(mlkem_msg_dest_valid.get_mirrored_value() >> bt);
            foreach(dma_data_dest_valid_bit_cg[bt]) this.dma_data_dest_valid_bit_cg[bt].sample(dma_data_dest_valid.get_mirrored_value() >> bt);
            foreach(rsvd_bit_cg[bt]) this.rsvd_bit_cg[bt].sample(rsvd.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( write_en.get_mirrored_value()  ,  write_entry.get_mirrored_value()  ,  hmac_key_dest_valid.get_mirrored_value()  ,  hmac_block_dest_valid.get_mirrored_value()  ,  mldsa_seed_dest_valid.get_mirrored_value()  ,  ecc_pkey_dest_valid.get_mirrored_value()  ,  ecc_seed_dest_valid.get_mirrored_value()  ,  aes_key_dest_valid.get_mirrored_value()  ,  mlkem_seed_dest_valid.get_mirrored_value()  ,  mlkem_msg_dest_valid.get_mirrored_value()  ,  dma_data_dest_valid.get_mirrored_value()  ,  rsvd.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__GLOBAL_INTR_EN_T SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__global_intr_en_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error_en_bit_cg[bt]) this.error_en_bit_cg[bt].sample(data[0 + bt]);
            foreach(notif_en_bit_cg[bt]) this.notif_en_bit_cg[bt].sample(data[1 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*error_en*/  ,  data[1:1]/*notif_en*/   );
        end
    endfunction

    function void aes_clp_reg__global_intr_en_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error_en_bit_cg[bt]) this.error_en_bit_cg[bt].sample(error_en.get_mirrored_value() >> bt);
            foreach(notif_en_bit_cg[bt]) this.notif_en_bit_cg[bt].sample(notif_en.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( error_en.get_mirrored_value()  ,  notif_en.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__ERROR_INTR_EN_T SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__error_intr_en_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error0_en_bit_cg[bt]) this.error0_en_bit_cg[bt].sample(data[0 + bt]);
            foreach(error1_en_bit_cg[bt]) this.error1_en_bit_cg[bt].sample(data[1 + bt]);
            foreach(error2_en_bit_cg[bt]) this.error2_en_bit_cg[bt].sample(data[2 + bt]);
            foreach(error3_en_bit_cg[bt]) this.error3_en_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*error0_en*/  ,  data[1:1]/*error1_en*/  ,  data[2:2]/*error2_en*/  ,  data[3:3]/*error3_en*/   );
        end
    endfunction

    function void aes_clp_reg__error_intr_en_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error0_en_bit_cg[bt]) this.error0_en_bit_cg[bt].sample(error0_en.get_mirrored_value() >> bt);
            foreach(error1_en_bit_cg[bt]) this.error1_en_bit_cg[bt].sample(error1_en.get_mirrored_value() >> bt);
            foreach(error2_en_bit_cg[bt]) this.error2_en_bit_cg[bt].sample(error2_en.get_mirrored_value() >> bt);
            foreach(error3_en_bit_cg[bt]) this.error3_en_bit_cg[bt].sample(error3_en.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( error0_en.get_mirrored_value()  ,  error1_en.get_mirrored_value()  ,  error2_en.get_mirrored_value()  ,  error3_en.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__NOTIF_INTR_EN_T SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__notif_intr_en_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_en_bit_cg[bt]) this.notif_cmd_done_en_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*notif_cmd_done_en*/   );
        end
    endfunction

    function void aes_clp_reg__notif_intr_en_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_en_bit_cg[bt]) this.notif_cmd_done_en_bit_cg[bt].sample(notif_cmd_done_en.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( notif_cmd_done_en.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__GLOBAL_INTR_T_AGG_STS_DD3DCF0A SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__global_intr_t_agg_sts_dd3dcf0a::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(agg_sts_bit_cg[bt]) this.agg_sts_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*agg_sts*/   );
        end
    endfunction

    function void aes_clp_reg__global_intr_t_agg_sts_dd3dcf0a::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(agg_sts_bit_cg[bt]) this.agg_sts_bit_cg[bt].sample(agg_sts.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( agg_sts.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__GLOBAL_INTR_T_AGG_STS_E6399B4A SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__global_intr_t_agg_sts_e6399b4a::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(agg_sts_bit_cg[bt]) this.agg_sts_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*agg_sts*/   );
        end
    endfunction

    function void aes_clp_reg__global_intr_t_agg_sts_e6399b4a::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(agg_sts_bit_cg[bt]) this.agg_sts_bit_cg[bt].sample(agg_sts.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( agg_sts.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__ERROR_INTR_T_ERROR0_STS_28545624_ERROR1_STS_40E0D3E1_ERROR2_STS_B1CF2205_ERROR3_STS_74A35378 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__error_intr_t_error0_sts_28545624_error1_sts_40e0d3e1_error2_sts_b1cf2205_error3_sts_74a35378::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error0_sts_bit_cg[bt]) this.error0_sts_bit_cg[bt].sample(data[0 + bt]);
            foreach(error1_sts_bit_cg[bt]) this.error1_sts_bit_cg[bt].sample(data[1 + bt]);
            foreach(error2_sts_bit_cg[bt]) this.error2_sts_bit_cg[bt].sample(data[2 + bt]);
            foreach(error3_sts_bit_cg[bt]) this.error3_sts_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*error0_sts*/  ,  data[1:1]/*error1_sts*/  ,  data[2:2]/*error2_sts*/  ,  data[3:3]/*error3_sts*/   );
        end
    endfunction

    function void aes_clp_reg__error_intr_t_error0_sts_28545624_error1_sts_40e0d3e1_error2_sts_b1cf2205_error3_sts_74a35378::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error0_sts_bit_cg[bt]) this.error0_sts_bit_cg[bt].sample(error0_sts.get_mirrored_value() >> bt);
            foreach(error1_sts_bit_cg[bt]) this.error1_sts_bit_cg[bt].sample(error1_sts.get_mirrored_value() >> bt);
            foreach(error2_sts_bit_cg[bt]) this.error2_sts_bit_cg[bt].sample(error2_sts.get_mirrored_value() >> bt);
            foreach(error3_sts_bit_cg[bt]) this.error3_sts_bit_cg[bt].sample(error3_sts.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( error0_sts.get_mirrored_value()  ,  error1_sts.get_mirrored_value()  ,  error2_sts.get_mirrored_value()  ,  error3_sts.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__NOTIF_INTR_T_NOTIF_CMD_DONE_STS_1C68637E SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__notif_intr_t_notif_cmd_done_sts_1c68637e::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_sts_bit_cg[bt]) this.notif_cmd_done_sts_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*notif_cmd_done_sts*/   );
        end
    endfunction

    function void aes_clp_reg__notif_intr_t_notif_cmd_done_sts_1c68637e::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_sts_bit_cg[bt]) this.notif_cmd_done_sts_bit_cg[bt].sample(notif_cmd_done_sts.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( notif_cmd_done_sts.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__ERROR_INTR_TRIG_T SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__error_intr_trig_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error0_trig_bit_cg[bt]) this.error0_trig_bit_cg[bt].sample(data[0 + bt]);
            foreach(error1_trig_bit_cg[bt]) this.error1_trig_bit_cg[bt].sample(data[1 + bt]);
            foreach(error2_trig_bit_cg[bt]) this.error2_trig_bit_cg[bt].sample(data[2 + bt]);
            foreach(error3_trig_bit_cg[bt]) this.error3_trig_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*error0_trig*/  ,  data[1:1]/*error1_trig*/  ,  data[2:2]/*error2_trig*/  ,  data[3:3]/*error3_trig*/   );
        end
    endfunction

    function void aes_clp_reg__error_intr_trig_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error0_trig_bit_cg[bt]) this.error0_trig_bit_cg[bt].sample(error0_trig.get_mirrored_value() >> bt);
            foreach(error1_trig_bit_cg[bt]) this.error1_trig_bit_cg[bt].sample(error1_trig.get_mirrored_value() >> bt);
            foreach(error2_trig_bit_cg[bt]) this.error2_trig_bit_cg[bt].sample(error2_trig.get_mirrored_value() >> bt);
            foreach(error3_trig_bit_cg[bt]) this.error3_trig_bit_cg[bt].sample(error3_trig.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( error0_trig.get_mirrored_value()  ,  error1_trig.get_mirrored_value()  ,  error2_trig.get_mirrored_value()  ,  error3_trig.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__NOTIF_INTR_TRIG_T SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__notif_intr_trig_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_trig_bit_cg[bt]) this.notif_cmd_done_trig_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*notif_cmd_done_trig*/   );
        end
    endfunction

    function void aes_clp_reg__notif_intr_trig_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_trig_bit_cg[bt]) this.notif_cmd_done_trig_bit_cg[bt].sample(notif_cmd_done_trig.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( notif_cmd_done_trig.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_35ACE267 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_t_cnt_35ace267::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*cnt*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_t_cnt_35ace267::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_73C42C28 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_t_cnt_73c42c28::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*cnt*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_t_cnt_73c42c28::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_D8AF96FF SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_t_cnt_d8af96ff::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*cnt*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_t_cnt_d8af96ff::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_9BD7F809 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_t_cnt_9bd7f809::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*cnt*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_t_cnt_9bd7f809::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_BE67D6D5 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_t_cnt_be67d6d5::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*cnt*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_t_cnt_be67d6d5::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_37026C97 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_incr_t_pulse_37026c97::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*pulse*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_incr_t_pulse_37026c97::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_D860D977 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_incr_t_pulse_d860d977::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*pulse*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_incr_t_pulse_d860d977::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_87B45FE7 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_incr_t_pulse_87b45fe7::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*pulse*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_incr_t_pulse_87b45fe7::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_C1689EE6 SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_incr_t_pulse_c1689ee6::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*pulse*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_incr_t_pulse_c1689ee6::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_6173128E SAMPLE FUNCTIONS -----------------------*/
    function void aes_clp_reg__intr_count_incr_t_pulse_6173128e::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*pulse*/   );
        end
    endfunction

    function void aes_clp_reg__intr_count_incr_t_pulse_6173128e::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

`endif