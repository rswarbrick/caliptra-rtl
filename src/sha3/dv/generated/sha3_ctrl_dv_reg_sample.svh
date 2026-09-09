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

`ifndef SHA3_CTRL_DV_REG_SAMPLE
    `define SHA3_CTRL_DV_REG_SAMPLE
    
    /*----------------------- KMAC_REG__INTR_STATE SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__INTR_STATE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KMAC_DONE_bit_cg[bt]) this.KMAC_DONE_bit_cg[bt].sample(data[0 + bt]);
            foreach(FIFO_EMPTY_bit_cg[bt]) this.FIFO_EMPTY_bit_cg[bt].sample(data[1 + bt]);
            foreach(KMAC_ERR_bit_cg[bt]) this.KMAC_ERR_bit_cg[bt].sample(data[2 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*KMAC_DONE*/  ,  data[1:1]/*FIFO_EMPTY*/  ,  data[2:2]/*KMAC_ERR*/   );
        end
    endfunction

    function void kmac_reg__INTR_STATE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KMAC_DONE_bit_cg[bt]) this.KMAC_DONE_bit_cg[bt].sample(KMAC_DONE.get_mirrored_value() >> bt);
            foreach(FIFO_EMPTY_bit_cg[bt]) this.FIFO_EMPTY_bit_cg[bt].sample(FIFO_EMPTY.get_mirrored_value() >> bt);
            foreach(KMAC_ERR_bit_cg[bt]) this.KMAC_ERR_bit_cg[bt].sample(KMAC_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( KMAC_DONE.get_mirrored_value()  ,  FIFO_EMPTY.get_mirrored_value()  ,  KMAC_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__INTR_ENABLE SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__INTR_ENABLE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KMAC_DONE_bit_cg[bt]) this.KMAC_DONE_bit_cg[bt].sample(data[0 + bt]);
            foreach(FIFO_EMPTY_bit_cg[bt]) this.FIFO_EMPTY_bit_cg[bt].sample(data[1 + bt]);
            foreach(KMAC_ERR_bit_cg[bt]) this.KMAC_ERR_bit_cg[bt].sample(data[2 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*KMAC_DONE*/  ,  data[1:1]/*FIFO_EMPTY*/  ,  data[2:2]/*KMAC_ERR*/   );
        end
    endfunction

    function void kmac_reg__INTR_ENABLE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KMAC_DONE_bit_cg[bt]) this.KMAC_DONE_bit_cg[bt].sample(KMAC_DONE.get_mirrored_value() >> bt);
            foreach(FIFO_EMPTY_bit_cg[bt]) this.FIFO_EMPTY_bit_cg[bt].sample(FIFO_EMPTY.get_mirrored_value() >> bt);
            foreach(KMAC_ERR_bit_cg[bt]) this.KMAC_ERR_bit_cg[bt].sample(KMAC_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( KMAC_DONE.get_mirrored_value()  ,  FIFO_EMPTY.get_mirrored_value()  ,  KMAC_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__INTR_TEST SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__INTR_TEST::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KMAC_DONE_bit_cg[bt]) this.KMAC_DONE_bit_cg[bt].sample(data[0 + bt]);
            foreach(FIFO_EMPTY_bit_cg[bt]) this.FIFO_EMPTY_bit_cg[bt].sample(data[1 + bt]);
            foreach(KMAC_ERR_bit_cg[bt]) this.KMAC_ERR_bit_cg[bt].sample(data[2 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*KMAC_DONE*/  ,  data[1:1]/*FIFO_EMPTY*/  ,  data[2:2]/*KMAC_ERR*/   );
        end
    endfunction

    function void kmac_reg__INTR_TEST::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(KMAC_DONE_bit_cg[bt]) this.KMAC_DONE_bit_cg[bt].sample(KMAC_DONE.get_mirrored_value() >> bt);
            foreach(FIFO_EMPTY_bit_cg[bt]) this.FIFO_EMPTY_bit_cg[bt].sample(FIFO_EMPTY.get_mirrored_value() >> bt);
            foreach(KMAC_ERR_bit_cg[bt]) this.KMAC_ERR_bit_cg[bt].sample(KMAC_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( KMAC_DONE.get_mirrored_value()  ,  FIFO_EMPTY.get_mirrored_value()  ,  KMAC_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__ALERT_TEST SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__ALERT_TEST::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(RECOV_OPERATION_ERR_bit_cg[bt]) this.RECOV_OPERATION_ERR_bit_cg[bt].sample(data[0 + bt]);
            foreach(FATAL_FAULT_ERR_bit_cg[bt]) this.FATAL_FAULT_ERR_bit_cg[bt].sample(data[1 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*RECOV_OPERATION_ERR*/  ,  data[1:1]/*FATAL_FAULT_ERR*/   );
        end
    endfunction

    function void kmac_reg__ALERT_TEST::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(RECOV_OPERATION_ERR_bit_cg[bt]) this.RECOV_OPERATION_ERR_bit_cg[bt].sample(RECOV_OPERATION_ERR.get_mirrored_value() >> bt);
            foreach(FATAL_FAULT_ERR_bit_cg[bt]) this.FATAL_FAULT_ERR_bit_cg[bt].sample(FATAL_FAULT_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( RECOV_OPERATION_ERR.get_mirrored_value()  ,  FATAL_FAULT_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__CFG_REGWEN SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__CFG_REGWEN::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(en_bit_cg[bt]) this.en_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*en*/   );
        end
    endfunction

    function void kmac_reg__CFG_REGWEN::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(en_bit_cg[bt]) this.en_bit_cg[bt].sample(en.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( en.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__CFG_SHADOWED SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__CFG_SHADOWED::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(kstrength_bit_cg[bt]) this.kstrength_bit_cg[bt].sample(data[1 + bt]);
            foreach(mode_bit_cg[bt]) this.mode_bit_cg[bt].sample(data[4 + bt]);
            foreach(msg_endianness_bit_cg[bt]) this.msg_endianness_bit_cg[bt].sample(data[8 + bt]);
            foreach(state_endianness_bit_cg[bt]) this.state_endianness_bit_cg[bt].sample(data[9 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[3:1]/*kstrength*/  ,  data[5:4]/*mode*/  ,  data[8:8]/*msg_endianness*/  ,  data[9:9]/*state_endianness*/   );
        end
    endfunction

    function void kmac_reg__CFG_SHADOWED::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(kstrength_bit_cg[bt]) this.kstrength_bit_cg[bt].sample(kstrength.get_mirrored_value() >> bt);
            foreach(mode_bit_cg[bt]) this.mode_bit_cg[bt].sample(mode.get_mirrored_value() >> bt);
            foreach(msg_endianness_bit_cg[bt]) this.msg_endianness_bit_cg[bt].sample(msg_endianness.get_mirrored_value() >> bt);
            foreach(state_endianness_bit_cg[bt]) this.state_endianness_bit_cg[bt].sample(state_endianness.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( kstrength.get_mirrored_value()  ,  mode.get_mirrored_value()  ,  msg_endianness.get_mirrored_value()  ,  state_endianness.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__CMD SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__CMD::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cmd_bit_cg[bt]) this.cmd_bit_cg[bt].sample(data[0 + bt]);
            foreach(err_processed_bit_cg[bt]) this.err_processed_bit_cg[bt].sample(data[10 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[5:0]/*cmd*/  ,  data[10:10]/*err_processed*/   );
        end
    endfunction

    function void kmac_reg__CMD::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cmd_bit_cg[bt]) this.cmd_bit_cg[bt].sample(cmd.get_mirrored_value() >> bt);
            foreach(err_processed_bit_cg[bt]) this.err_processed_bit_cg[bt].sample(err_processed.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cmd.get_mirrored_value()  ,  err_processed.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__STATUS SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__STATUS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_idle_bit_cg[bt]) this.sha3_idle_bit_cg[bt].sample(data[0 + bt]);
            foreach(sha3_absorb_bit_cg[bt]) this.sha3_absorb_bit_cg[bt].sample(data[1 + bt]);
            foreach(sha3_squeeze_bit_cg[bt]) this.sha3_squeeze_bit_cg[bt].sample(data[2 + bt]);
            foreach(fifo_depth_bit_cg[bt]) this.fifo_depth_bit_cg[bt].sample(data[8 + bt]);
            foreach(fifo_empty_bit_cg[bt]) this.fifo_empty_bit_cg[bt].sample(data[14 + bt]);
            foreach(fifo_full_bit_cg[bt]) this.fifo_full_bit_cg[bt].sample(data[15 + bt]);
            foreach(ALERT_FATAL_FAULT_bit_cg[bt]) this.ALERT_FATAL_FAULT_bit_cg[bt].sample(data[16 + bt]);
            foreach(ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt]) this.ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt].sample(data[17 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*sha3_idle*/  ,  data[1:1]/*sha3_absorb*/  ,  data[2:2]/*sha3_squeeze*/  ,  data[12:8]/*fifo_depth*/  ,  data[14:14]/*fifo_empty*/  ,  data[15:15]/*fifo_full*/  ,  data[16:16]/*ALERT_FATAL_FAULT*/  ,  data[17:17]/*ALERT_RECOV_CTRL_UPDATE_ERR*/   );
        end
    endfunction

    function void kmac_reg__STATUS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_idle_bit_cg[bt]) this.sha3_idle_bit_cg[bt].sample(sha3_idle.get_mirrored_value() >> bt);
            foreach(sha3_absorb_bit_cg[bt]) this.sha3_absorb_bit_cg[bt].sample(sha3_absorb.get_mirrored_value() >> bt);
            foreach(sha3_squeeze_bit_cg[bt]) this.sha3_squeeze_bit_cg[bt].sample(sha3_squeeze.get_mirrored_value() >> bt);
            foreach(fifo_depth_bit_cg[bt]) this.fifo_depth_bit_cg[bt].sample(fifo_depth.get_mirrored_value() >> bt);
            foreach(fifo_empty_bit_cg[bt]) this.fifo_empty_bit_cg[bt].sample(fifo_empty.get_mirrored_value() >> bt);
            foreach(fifo_full_bit_cg[bt]) this.fifo_full_bit_cg[bt].sample(fifo_full.get_mirrored_value() >> bt);
            foreach(ALERT_FATAL_FAULT_bit_cg[bt]) this.ALERT_FATAL_FAULT_bit_cg[bt].sample(ALERT_FATAL_FAULT.get_mirrored_value() >> bt);
            foreach(ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt]) this.ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt].sample(ALERT_RECOV_CTRL_UPDATE_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( sha3_idle.get_mirrored_value()  ,  sha3_absorb.get_mirrored_value()  ,  sha3_squeeze.get_mirrored_value()  ,  fifo_depth.get_mirrored_value()  ,  fifo_empty.get_mirrored_value()  ,  fifo_full.get_mirrored_value()  ,  ALERT_FATAL_FAULT.get_mirrored_value()  ,  ALERT_RECOV_CTRL_UPDATE_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_0 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_0::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_0::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_1 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_1::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_1::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_2 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_2::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_2::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_3 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_3::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_3::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_4 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_4::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_4::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_5 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_5::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_5::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_6 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_6::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_6::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_7 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_7::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_7::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_8 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_8::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_8::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_9 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_9::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_9::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__PREFIX_10 SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__PREFIX_10::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*PREFIX*/   );
        end
    endfunction

    function void kmac_reg__PREFIX_10::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(PREFIX_bit_cg[bt]) this.PREFIX_bit_cg[bt].sample(PREFIX.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( PREFIX.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- KMAC_REG__ERR_CODE SAMPLE FUNCTIONS -----------------------*/
    function void kmac_reg__ERR_CODE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ERR_CODE_bit_cg[bt]) this.ERR_CODE_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*ERR_CODE*/   );
        end
    endfunction

    function void kmac_reg__ERR_CODE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ERR_CODE_bit_cg[bt]) this.ERR_CODE_bit_cg[bt].sample(ERR_CODE.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ERR_CODE.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__SHA3_NAME SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__SHA3_NAME::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__SHA3_NAME::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(NAME_bit_cg[bt]) this.NAME_bit_cg[bt].sample(NAME.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( NAME.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__SHA3_VERSION SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__SHA3_VERSION::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__SHA3_VERSION::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(VERSION_bit_cg[bt]) this.VERSION_bit_cg[bt].sample(VERSION.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( VERSION.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__ALERT_TEST SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__ALERT_TEST::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(RECOV_OPERATION_ERR_bit_cg[bt]) this.RECOV_OPERATION_ERR_bit_cg[bt].sample(data[0 + bt]);
            foreach(FATAL_FAULT_ERR_bit_cg[bt]) this.FATAL_FAULT_ERR_bit_cg[bt].sample(data[1 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*RECOV_OPERATION_ERR*/  ,  data[1:1]/*FATAL_FAULT_ERR*/   );
        end
    endfunction

    function void sha3_reg__ALERT_TEST::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(RECOV_OPERATION_ERR_bit_cg[bt]) this.RECOV_OPERATION_ERR_bit_cg[bt].sample(RECOV_OPERATION_ERR.get_mirrored_value() >> bt);
            foreach(FATAL_FAULT_ERR_bit_cg[bt]) this.FATAL_FAULT_ERR_bit_cg[bt].sample(FATAL_FAULT_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( RECOV_OPERATION_ERR.get_mirrored_value()  ,  FATAL_FAULT_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__CFG_REGWEN SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__CFG_REGWEN::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(en_bit_cg[bt]) this.en_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*en*/   );
        end
    endfunction

    function void sha3_reg__CFG_REGWEN::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(en_bit_cg[bt]) this.en_bit_cg[bt].sample(en.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( en.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__CFG_SHADOWED SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__CFG_SHADOWED::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(kstrength_bit_cg[bt]) this.kstrength_bit_cg[bt].sample(data[1 + bt]);
            foreach(mode_bit_cg[bt]) this.mode_bit_cg[bt].sample(data[4 + bt]);
            foreach(msg_endianness_bit_cg[bt]) this.msg_endianness_bit_cg[bt].sample(data[8 + bt]);
            foreach(state_endianness_bit_cg[bt]) this.state_endianness_bit_cg[bt].sample(data[9 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[3:1]/*kstrength*/  ,  data[5:4]/*mode*/  ,  data[8:8]/*msg_endianness*/  ,  data[9:9]/*state_endianness*/   );
        end
    endfunction

    function void sha3_reg__CFG_SHADOWED::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(kstrength_bit_cg[bt]) this.kstrength_bit_cg[bt].sample(kstrength.get_mirrored_value() >> bt);
            foreach(mode_bit_cg[bt]) this.mode_bit_cg[bt].sample(mode.get_mirrored_value() >> bt);
            foreach(msg_endianness_bit_cg[bt]) this.msg_endianness_bit_cg[bt].sample(msg_endianness.get_mirrored_value() >> bt);
            foreach(state_endianness_bit_cg[bt]) this.state_endianness_bit_cg[bt].sample(state_endianness.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( kstrength.get_mirrored_value()  ,  mode.get_mirrored_value()  ,  msg_endianness.get_mirrored_value()  ,  state_endianness.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__CMD SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__CMD::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cmd_bit_cg[bt]) this.cmd_bit_cg[bt].sample(data[0 + bt]);
            foreach(err_processed_bit_cg[bt]) this.err_processed_bit_cg[bt].sample(data[10 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[5:0]/*cmd*/  ,  data[10:10]/*err_processed*/   );
        end
    endfunction

    function void sha3_reg__CMD::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cmd_bit_cg[bt]) this.cmd_bit_cg[bt].sample(cmd.get_mirrored_value() >> bt);
            foreach(err_processed_bit_cg[bt]) this.err_processed_bit_cg[bt].sample(err_processed.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cmd.get_mirrored_value()  ,  err_processed.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__STATUS SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__STATUS::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_idle_bit_cg[bt]) this.sha3_idle_bit_cg[bt].sample(data[0 + bt]);
            foreach(sha3_absorb_bit_cg[bt]) this.sha3_absorb_bit_cg[bt].sample(data[1 + bt]);
            foreach(sha3_squeeze_bit_cg[bt]) this.sha3_squeeze_bit_cg[bt].sample(data[2 + bt]);
            foreach(fifo_depth_bit_cg[bt]) this.fifo_depth_bit_cg[bt].sample(data[8 + bt]);
            foreach(fifo_empty_bit_cg[bt]) this.fifo_empty_bit_cg[bt].sample(data[14 + bt]);
            foreach(fifo_full_bit_cg[bt]) this.fifo_full_bit_cg[bt].sample(data[15 + bt]);
            foreach(ALERT_FATAL_FAULT_bit_cg[bt]) this.ALERT_FATAL_FAULT_bit_cg[bt].sample(data[16 + bt]);
            foreach(ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt]) this.ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt].sample(data[17 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*sha3_idle*/  ,  data[1:1]/*sha3_absorb*/  ,  data[2:2]/*sha3_squeeze*/  ,  data[12:8]/*fifo_depth*/  ,  data[14:14]/*fifo_empty*/  ,  data[15:15]/*fifo_full*/  ,  data[16:16]/*ALERT_FATAL_FAULT*/  ,  data[17:17]/*ALERT_RECOV_CTRL_UPDATE_ERR*/   );
        end
    endfunction

    function void sha3_reg__STATUS::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_idle_bit_cg[bt]) this.sha3_idle_bit_cg[bt].sample(sha3_idle.get_mirrored_value() >> bt);
            foreach(sha3_absorb_bit_cg[bt]) this.sha3_absorb_bit_cg[bt].sample(sha3_absorb.get_mirrored_value() >> bt);
            foreach(sha3_squeeze_bit_cg[bt]) this.sha3_squeeze_bit_cg[bt].sample(sha3_squeeze.get_mirrored_value() >> bt);
            foreach(fifo_depth_bit_cg[bt]) this.fifo_depth_bit_cg[bt].sample(fifo_depth.get_mirrored_value() >> bt);
            foreach(fifo_empty_bit_cg[bt]) this.fifo_empty_bit_cg[bt].sample(fifo_empty.get_mirrored_value() >> bt);
            foreach(fifo_full_bit_cg[bt]) this.fifo_full_bit_cg[bt].sample(fifo_full.get_mirrored_value() >> bt);
            foreach(ALERT_FATAL_FAULT_bit_cg[bt]) this.ALERT_FATAL_FAULT_bit_cg[bt].sample(ALERT_FATAL_FAULT.get_mirrored_value() >> bt);
            foreach(ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt]) this.ALERT_RECOV_CTRL_UPDATE_ERR_bit_cg[bt].sample(ALERT_RECOV_CTRL_UPDATE_ERR.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( sha3_idle.get_mirrored_value()  ,  sha3_absorb.get_mirrored_value()  ,  sha3_squeeze.get_mirrored_value()  ,  fifo_depth.get_mirrored_value()  ,  fifo_empty.get_mirrored_value()  ,  fifo_full.get_mirrored_value()  ,  ALERT_FATAL_FAULT.get_mirrored_value()  ,  ALERT_RECOV_CTRL_UPDATE_ERR.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__ERR_CODE SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__ERR_CODE::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ERR_CODE_bit_cg[bt]) this.ERR_CODE_bit_cg[bt].sample(data[0 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[31:0]/*ERR_CODE*/   );
        end
    endfunction

    function void sha3_reg__ERR_CODE::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(ERR_CODE_bit_cg[bt]) this.ERR_CODE_bit_cg[bt].sample(ERR_CODE.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( ERR_CODE.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__GLOBAL_INTR_EN_T SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__global_intr_en_t::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__global_intr_en_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(error_en_bit_cg[bt]) this.error_en_bit_cg[bt].sample(error_en.get_mirrored_value() >> bt);
            foreach(notif_en_bit_cg[bt]) this.notif_en_bit_cg[bt].sample(notif_en.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( error_en.get_mirrored_value()  ,  notif_en.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__ERROR_INTR_EN_T SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__error_intr_en_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_error_en_bit_cg[bt]) this.sha3_error_en_bit_cg[bt].sample(data[0 + bt]);
            foreach(error1_en_bit_cg[bt]) this.error1_en_bit_cg[bt].sample(data[1 + bt]);
            foreach(error2_en_bit_cg[bt]) this.error2_en_bit_cg[bt].sample(data[2 + bt]);
            foreach(error3_en_bit_cg[bt]) this.error3_en_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*sha3_error_en*/  ,  data[1:1]/*error1_en*/  ,  data[2:2]/*error2_en*/  ,  data[3:3]/*error3_en*/   );
        end
    endfunction

    function void sha3_reg__error_intr_en_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_error_en_bit_cg[bt]) this.sha3_error_en_bit_cg[bt].sample(sha3_error_en.get_mirrored_value() >> bt);
            foreach(error1_en_bit_cg[bt]) this.error1_en_bit_cg[bt].sample(error1_en.get_mirrored_value() >> bt);
            foreach(error2_en_bit_cg[bt]) this.error2_en_bit_cg[bt].sample(error2_en.get_mirrored_value() >> bt);
            foreach(error3_en_bit_cg[bt]) this.error3_en_bit_cg[bt].sample(error3_en.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( sha3_error_en.get_mirrored_value()  ,  error1_en.get_mirrored_value()  ,  error2_en.get_mirrored_value()  ,  error3_en.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__NOTIF_INTR_EN_T SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__notif_intr_en_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_en_bit_cg[bt]) this.notif_cmd_done_en_bit_cg[bt].sample(data[0 + bt]);
            foreach(notif_msg_fifo_empty_en_bit_cg[bt]) this.notif_msg_fifo_empty_en_bit_cg[bt].sample(data[1 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*notif_cmd_done_en*/  ,  data[1:1]/*notif_msg_fifo_empty_en*/   );
        end
    endfunction

    function void sha3_reg__notif_intr_en_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_en_bit_cg[bt]) this.notif_cmd_done_en_bit_cg[bt].sample(notif_cmd_done_en.get_mirrored_value() >> bt);
            foreach(notif_msg_fifo_empty_en_bit_cg[bt]) this.notif_msg_fifo_empty_en_bit_cg[bt].sample(notif_msg_fifo_empty_en.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( notif_cmd_done_en.get_mirrored_value()  ,  notif_msg_fifo_empty_en.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__GLOBAL_INTR_T_AGG_STS_DD3DCF0A SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__global_intr_t_agg_sts_dd3dcf0a::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__global_intr_t_agg_sts_dd3dcf0a::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(agg_sts_bit_cg[bt]) this.agg_sts_bit_cg[bt].sample(agg_sts.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( agg_sts.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__GLOBAL_INTR_T_AGG_STS_E6399B4A SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__global_intr_t_agg_sts_e6399b4a::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__global_intr_t_agg_sts_e6399b4a::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(agg_sts_bit_cg[bt]) this.agg_sts_bit_cg[bt].sample(agg_sts.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( agg_sts.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__ERROR_INTR_T_ERROR1_STS_40E0D3E1_ERROR2_STS_B1CF2205_ERROR3_STS_74A35378_SHA3_ERROR_STS_A3CFDCF2 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__error_intr_t_error1_sts_40e0d3e1_error2_sts_b1cf2205_error3_sts_74a35378_sha3_error_sts_a3cfdcf2::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_error_sts_bit_cg[bt]) this.sha3_error_sts_bit_cg[bt].sample(data[0 + bt]);
            foreach(error1_sts_bit_cg[bt]) this.error1_sts_bit_cg[bt].sample(data[1 + bt]);
            foreach(error2_sts_bit_cg[bt]) this.error2_sts_bit_cg[bt].sample(data[2 + bt]);
            foreach(error3_sts_bit_cg[bt]) this.error3_sts_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*sha3_error_sts*/  ,  data[1:1]/*error1_sts*/  ,  data[2:2]/*error2_sts*/  ,  data[3:3]/*error3_sts*/   );
        end
    endfunction

    function void sha3_reg__error_intr_t_error1_sts_40e0d3e1_error2_sts_b1cf2205_error3_sts_74a35378_sha3_error_sts_a3cfdcf2::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_error_sts_bit_cg[bt]) this.sha3_error_sts_bit_cg[bt].sample(sha3_error_sts.get_mirrored_value() >> bt);
            foreach(error1_sts_bit_cg[bt]) this.error1_sts_bit_cg[bt].sample(error1_sts.get_mirrored_value() >> bt);
            foreach(error2_sts_bit_cg[bt]) this.error2_sts_bit_cg[bt].sample(error2_sts.get_mirrored_value() >> bt);
            foreach(error3_sts_bit_cg[bt]) this.error3_sts_bit_cg[bt].sample(error3_sts.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( sha3_error_sts.get_mirrored_value()  ,  error1_sts.get_mirrored_value()  ,  error2_sts.get_mirrored_value()  ,  error3_sts.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__NOTIF_INTR_T_NOTIF_CMD_DONE_STS_1C68637E_NOTIF_MSG_FIFO_EMPTY_STS_DF694E73 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__notif_intr_t_notif_cmd_done_sts_1c68637e_notif_msg_fifo_empty_sts_df694e73::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_sts_bit_cg[bt]) this.notif_cmd_done_sts_bit_cg[bt].sample(data[0 + bt]);
            foreach(notif_msg_fifo_empty_sts_bit_cg[bt]) this.notif_msg_fifo_empty_sts_bit_cg[bt].sample(data[1 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*notif_cmd_done_sts*/  ,  data[1:1]/*notif_msg_fifo_empty_sts*/   );
        end
    endfunction

    function void sha3_reg__notif_intr_t_notif_cmd_done_sts_1c68637e_notif_msg_fifo_empty_sts_df694e73::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_sts_bit_cg[bt]) this.notif_cmd_done_sts_bit_cg[bt].sample(notif_cmd_done_sts.get_mirrored_value() >> bt);
            foreach(notif_msg_fifo_empty_sts_bit_cg[bt]) this.notif_msg_fifo_empty_sts_bit_cg[bt].sample(notif_msg_fifo_empty_sts.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( notif_cmd_done_sts.get_mirrored_value()  ,  notif_msg_fifo_empty_sts.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__ERROR_INTR_TRIG_T SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__error_intr_trig_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_error_trig_bit_cg[bt]) this.sha3_error_trig_bit_cg[bt].sample(data[0 + bt]);
            foreach(error1_trig_bit_cg[bt]) this.error1_trig_bit_cg[bt].sample(data[1 + bt]);
            foreach(error2_trig_bit_cg[bt]) this.error2_trig_bit_cg[bt].sample(data[2 + bt]);
            foreach(error3_trig_bit_cg[bt]) this.error3_trig_bit_cg[bt].sample(data[3 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*sha3_error_trig*/  ,  data[1:1]/*error1_trig*/  ,  data[2:2]/*error2_trig*/  ,  data[3:3]/*error3_trig*/   );
        end
    endfunction

    function void sha3_reg__error_intr_trig_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(sha3_error_trig_bit_cg[bt]) this.sha3_error_trig_bit_cg[bt].sample(sha3_error_trig.get_mirrored_value() >> bt);
            foreach(error1_trig_bit_cg[bt]) this.error1_trig_bit_cg[bt].sample(error1_trig.get_mirrored_value() >> bt);
            foreach(error2_trig_bit_cg[bt]) this.error2_trig_bit_cg[bt].sample(error2_trig.get_mirrored_value() >> bt);
            foreach(error3_trig_bit_cg[bt]) this.error3_trig_bit_cg[bt].sample(error3_trig.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( sha3_error_trig.get_mirrored_value()  ,  error1_trig.get_mirrored_value()  ,  error2_trig.get_mirrored_value()  ,  error3_trig.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__NOTIF_INTR_TRIG_T SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__notif_intr_trig_t::sample(uvm_reg_data_t  data,
                                                   uvm_reg_data_t  byte_en,
                                                   bit             is_read,
                                                   uvm_reg_map     map);
        m_current = get();
        m_data    = data;
        m_is_read = is_read;
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_trig_bit_cg[bt]) this.notif_cmd_done_trig_bit_cg[bt].sample(data[0 + bt]);
            foreach(notif_msg_fifo_empty_trig_bit_cg[bt]) this.notif_msg_fifo_empty_trig_bit_cg[bt].sample(data[1 + bt]);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( data[0:0]/*notif_cmd_done_trig*/  ,  data[1:1]/*notif_msg_fifo_empty_trig*/   );
        end
    endfunction

    function void sha3_reg__notif_intr_trig_t::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(notif_cmd_done_trig_bit_cg[bt]) this.notif_cmd_done_trig_bit_cg[bt].sample(notif_cmd_done_trig.get_mirrored_value() >> bt);
            foreach(notif_msg_fifo_empty_trig_bit_cg[bt]) this.notif_msg_fifo_empty_trig_bit_cg[bt].sample(notif_msg_fifo_empty_trig.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( notif_cmd_done_trig.get_mirrored_value()  ,  notif_msg_fifo_empty_trig.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_9198FA18 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_t_cnt_9198fa18::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_t_cnt_9198fa18::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_73C42C28 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_t_cnt_73c42c28::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_t_cnt_73c42c28::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_D8AF96FF SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_t_cnt_d8af96ff::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_t_cnt_d8af96ff::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_9BD7F809 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_t_cnt_9bd7f809::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_t_cnt_9bd7f809::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_BE67D6D5 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_t_cnt_be67d6d5::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_t_cnt_be67d6d5::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(cnt_bit_cg[bt]) this.cnt_bit_cg[bt].sample(cnt.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( cnt.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_D65B5E88 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_incr_t_pulse_d65b5e88::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_incr_t_pulse_d65b5e88::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_D860D977 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_incr_t_pulse_d860d977::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_incr_t_pulse_d860d977::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_87B45FE7 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_incr_t_pulse_87b45fe7::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_incr_t_pulse_87b45fe7::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_C1689EE6 SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_incr_t_pulse_c1689ee6::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_incr_t_pulse_c1689ee6::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_6173128E SAMPLE FUNCTIONS -----------------------*/
    function void sha3_reg__intr_count_incr_t_pulse_6173128e::sample(uvm_reg_data_t  data,
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

    function void sha3_reg__intr_count_incr_t_pulse_6173128e::sample_values();
        if (get_coverage(UVM_CVR_REG_BITS)) begin
            foreach(pulse_bit_cg[bt]) this.pulse_bit_cg[bt].sample(pulse.get_mirrored_value() >> bt);
        end
        if (get_coverage(UVM_CVR_FIELD_VALS)) begin
            this.fld_cg.sample( pulse.get_mirrored_value()   );
        end
    endfunction

`endif