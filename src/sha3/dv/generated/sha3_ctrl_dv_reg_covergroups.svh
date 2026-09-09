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

`ifndef SHA3_CTRL_DV_REG_COVERGROUPS
    `define SHA3_CTRL_DV_REG_COVERGROUPS
    
    /*----------------------- KMAC_REG__INTR_STATE COVERGROUPS -----------------------*/
    covergroup kmac_reg__INTR_STATE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__INTR_STATE_fld_cg with function sample(
    input bit [1-1:0] KMAC_DONE,
    input bit [1-1:0] FIFO_EMPTY,
    input bit [1-1:0] KMAC_ERR
    );
        option.per_instance = 1;
        KMAC_DONE_cp : coverpoint KMAC_DONE;
        FIFO_EMPTY_cp : coverpoint FIFO_EMPTY;
        KMAC_ERR_cp : coverpoint KMAC_ERR;

    endgroup

    /*----------------------- KMAC_REG__INTR_ENABLE COVERGROUPS -----------------------*/
    covergroup kmac_reg__INTR_ENABLE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__INTR_ENABLE_fld_cg with function sample(
    input bit [1-1:0] KMAC_DONE,
    input bit [1-1:0] FIFO_EMPTY,
    input bit [1-1:0] KMAC_ERR
    );
        option.per_instance = 1;
        KMAC_DONE_cp : coverpoint KMAC_DONE;
        FIFO_EMPTY_cp : coverpoint FIFO_EMPTY;
        KMAC_ERR_cp : coverpoint KMAC_ERR;

    endgroup

    /*----------------------- KMAC_REG__INTR_TEST COVERGROUPS -----------------------*/
    covergroup kmac_reg__INTR_TEST_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__INTR_TEST_fld_cg with function sample(
    input bit [1-1:0] KMAC_DONE,
    input bit [1-1:0] FIFO_EMPTY,
    input bit [1-1:0] KMAC_ERR
    );
        option.per_instance = 1;
        KMAC_DONE_cp : coverpoint KMAC_DONE;
        FIFO_EMPTY_cp : coverpoint FIFO_EMPTY;
        KMAC_ERR_cp : coverpoint KMAC_ERR;

    endgroup

    /*----------------------- KMAC_REG__ALERT_TEST COVERGROUPS -----------------------*/
    covergroup kmac_reg__ALERT_TEST_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__ALERT_TEST_fld_cg with function sample(
    input bit [1-1:0] RECOV_OPERATION_ERR,
    input bit [1-1:0] FATAL_FAULT_ERR
    );
        option.per_instance = 1;
        RECOV_OPERATION_ERR_cp : coverpoint RECOV_OPERATION_ERR;
        FATAL_FAULT_ERR_cp : coverpoint FATAL_FAULT_ERR;

    endgroup

    /*----------------------- KMAC_REG__CFG_REGWEN COVERGROUPS -----------------------*/
    covergroup kmac_reg__CFG_REGWEN_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__CFG_REGWEN_fld_cg with function sample(
    input bit [1-1:0] en
    );
        option.per_instance = 1;
        en_cp : coverpoint en;

    endgroup

    /*----------------------- KMAC_REG__CFG_SHADOWED COVERGROUPS -----------------------*/
    covergroup kmac_reg__CFG_SHADOWED_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__CFG_SHADOWED_fld_cg with function sample(
    input bit [3-1:0] kstrength,
    input bit [2-1:0] mode,
    input bit [1-1:0] msg_endianness,
    input bit [1-1:0] state_endianness
    );
        option.per_instance = 1;
        kstrength_cp : coverpoint kstrength;
        mode_cp : coverpoint mode;
        msg_endianness_cp : coverpoint msg_endianness;
        state_endianness_cp : coverpoint state_endianness;

    endgroup

    /*----------------------- KMAC_REG__CMD COVERGROUPS -----------------------*/
    covergroup kmac_reg__CMD_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__CMD_fld_cg with function sample(
    input bit [6-1:0] cmd,
    input bit [1-1:0] err_processed
    );
        option.per_instance = 1;
        cmd_cp : coverpoint cmd;
        err_processed_cp : coverpoint err_processed;

    endgroup

    /*----------------------- KMAC_REG__STATUS COVERGROUPS -----------------------*/
    covergroup kmac_reg__STATUS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__STATUS_fld_cg with function sample(
    input bit [1-1:0] sha3_idle,
    input bit [1-1:0] sha3_absorb,
    input bit [1-1:0] sha3_squeeze,
    input bit [5-1:0] fifo_depth,
    input bit [1-1:0] fifo_empty,
    input bit [1-1:0] fifo_full,
    input bit [1-1:0] ALERT_FATAL_FAULT,
    input bit [1-1:0] ALERT_RECOV_CTRL_UPDATE_ERR
    );
        option.per_instance = 1;
        sha3_idle_cp : coverpoint sha3_idle;
        sha3_absorb_cp : coverpoint sha3_absorb;
        sha3_squeeze_cp : coverpoint sha3_squeeze;
        fifo_depth_cp : coverpoint fifo_depth;
        fifo_empty_cp : coverpoint fifo_empty;
        fifo_full_cp : coverpoint fifo_full;
        ALERT_FATAL_FAULT_cp : coverpoint ALERT_FATAL_FAULT;
        ALERT_RECOV_CTRL_UPDATE_ERR_cp : coverpoint ALERT_RECOV_CTRL_UPDATE_ERR;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_0 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_0_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_0_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_1 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_1_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_1_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_2 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_2_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_2_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_3 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_3_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_3_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_4 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_4_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_4_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_5 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_5_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_5_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_6 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_6_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_6_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_7 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_7_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_7_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_8 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_8_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_8_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_9 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_9_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_9_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__PREFIX_10 COVERGROUPS -----------------------*/
    covergroup kmac_reg__PREFIX_10_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__PREFIX_10_fld_cg with function sample(
    input bit [32-1:0] PREFIX
    );
        option.per_instance = 1;
        PREFIX_cp : coverpoint PREFIX;

    endgroup

    /*----------------------- KMAC_REG__ERR_CODE COVERGROUPS -----------------------*/
    covergroup kmac_reg__ERR_CODE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kmac_reg__ERR_CODE_fld_cg with function sample(
    input bit [32-1:0] ERR_CODE
    );
        option.per_instance = 1;
        ERR_CODE_cp : coverpoint ERR_CODE;

    endgroup

    /*----------------------- SHA3_REG__SHA3_NAME COVERGROUPS -----------------------*/
    covergroup sha3_reg__SHA3_NAME_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__SHA3_NAME_fld_cg with function sample(
    input bit [32-1:0] NAME
    );
        option.per_instance = 1;
        NAME_cp : coverpoint NAME;

    endgroup

    /*----------------------- SHA3_REG__SHA3_VERSION COVERGROUPS -----------------------*/
    covergroup sha3_reg__SHA3_VERSION_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__SHA3_VERSION_fld_cg with function sample(
    input bit [32-1:0] VERSION
    );
        option.per_instance = 1;
        VERSION_cp : coverpoint VERSION;

    endgroup

    /*----------------------- SHA3_REG__ALERT_TEST COVERGROUPS -----------------------*/
    covergroup sha3_reg__ALERT_TEST_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__ALERT_TEST_fld_cg with function sample(
    input bit [1-1:0] RECOV_OPERATION_ERR,
    input bit [1-1:0] FATAL_FAULT_ERR
    );
        option.per_instance = 1;
        RECOV_OPERATION_ERR_cp : coverpoint RECOV_OPERATION_ERR;
        FATAL_FAULT_ERR_cp : coverpoint FATAL_FAULT_ERR;

    endgroup

    /*----------------------- SHA3_REG__CFG_REGWEN COVERGROUPS -----------------------*/
    covergroup sha3_reg__CFG_REGWEN_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__CFG_REGWEN_fld_cg with function sample(
    input bit [1-1:0] en
    );
        option.per_instance = 1;
        en_cp : coverpoint en;

    endgroup

    /*----------------------- SHA3_REG__CFG_SHADOWED COVERGROUPS -----------------------*/
    covergroup sha3_reg__CFG_SHADOWED_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__CFG_SHADOWED_fld_cg with function sample(
    input bit [3-1:0] kstrength,
    input bit [2-1:0] mode,
    input bit [1-1:0] msg_endianness,
    input bit [1-1:0] state_endianness
    );
        option.per_instance = 1;
        kstrength_cp : coverpoint kstrength;
        mode_cp : coverpoint mode;
        msg_endianness_cp : coverpoint msg_endianness;
        state_endianness_cp : coverpoint state_endianness;

    endgroup

    /*----------------------- SHA3_REG__CMD COVERGROUPS -----------------------*/
    covergroup sha3_reg__CMD_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__CMD_fld_cg with function sample(
    input bit [6-1:0] cmd,
    input bit [1-1:0] err_processed
    );
        option.per_instance = 1;
        cmd_cp : coverpoint cmd;
        err_processed_cp : coverpoint err_processed;

    endgroup

    /*----------------------- SHA3_REG__STATUS COVERGROUPS -----------------------*/
    covergroup sha3_reg__STATUS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__STATUS_fld_cg with function sample(
    input bit [1-1:0] sha3_idle,
    input bit [1-1:0] sha3_absorb,
    input bit [1-1:0] sha3_squeeze,
    input bit [5-1:0] fifo_depth,
    input bit [1-1:0] fifo_empty,
    input bit [1-1:0] fifo_full,
    input bit [1-1:0] ALERT_FATAL_FAULT,
    input bit [1-1:0] ALERT_RECOV_CTRL_UPDATE_ERR
    );
        option.per_instance = 1;
        sha3_idle_cp : coverpoint sha3_idle;
        sha3_absorb_cp : coverpoint sha3_absorb;
        sha3_squeeze_cp : coverpoint sha3_squeeze;
        fifo_depth_cp : coverpoint fifo_depth;
        fifo_empty_cp : coverpoint fifo_empty;
        fifo_full_cp : coverpoint fifo_full;
        ALERT_FATAL_FAULT_cp : coverpoint ALERT_FATAL_FAULT;
        ALERT_RECOV_CTRL_UPDATE_ERR_cp : coverpoint ALERT_RECOV_CTRL_UPDATE_ERR;

    endgroup

    /*----------------------- SHA3_REG__ERR_CODE COVERGROUPS -----------------------*/
    covergroup sha3_reg__ERR_CODE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__ERR_CODE_fld_cg with function sample(
    input bit [32-1:0] ERR_CODE
    );
        option.per_instance = 1;
        ERR_CODE_cp : coverpoint ERR_CODE;

    endgroup

    /*----------------------- SHA3_REG__GLOBAL_INTR_EN_T COVERGROUPS -----------------------*/
    covergroup sha3_reg__global_intr_en_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__global_intr_en_t_fld_cg with function sample(
    input bit [1-1:0] error_en,
    input bit [1-1:0] notif_en
    );
        option.per_instance = 1;
        error_en_cp : coverpoint error_en;
        notif_en_cp : coverpoint notif_en;

    endgroup

    /*----------------------- SHA3_REG__ERROR_INTR_EN_T COVERGROUPS -----------------------*/
    covergroup sha3_reg__error_intr_en_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__error_intr_en_t_fld_cg with function sample(
    input bit [1-1:0] sha3_error_en,
    input bit [1-1:0] error1_en,
    input bit [1-1:0] error2_en,
    input bit [1-1:0] error3_en
    );
        option.per_instance = 1;
        sha3_error_en_cp : coverpoint sha3_error_en;
        error1_en_cp : coverpoint error1_en;
        error2_en_cp : coverpoint error2_en;
        error3_en_cp : coverpoint error3_en;

    endgroup

    /*----------------------- SHA3_REG__NOTIF_INTR_EN_T COVERGROUPS -----------------------*/
    covergroup sha3_reg__notif_intr_en_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__notif_intr_en_t_fld_cg with function sample(
    input bit [1-1:0] notif_cmd_done_en,
    input bit [1-1:0] notif_msg_fifo_empty_en
    );
        option.per_instance = 1;
        notif_cmd_done_en_cp : coverpoint notif_cmd_done_en;
        notif_msg_fifo_empty_en_cp : coverpoint notif_msg_fifo_empty_en;

    endgroup

    /*----------------------- SHA3_REG__GLOBAL_INTR_T_AGG_STS_DD3DCF0A COVERGROUPS -----------------------*/
    covergroup sha3_reg__global_intr_t_agg_sts_dd3dcf0a_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__global_intr_t_agg_sts_dd3dcf0a_fld_cg with function sample(
    input bit [1-1:0] agg_sts
    );
        option.per_instance = 1;
        agg_sts_cp : coverpoint agg_sts;

    endgroup

    /*----------------------- SHA3_REG__GLOBAL_INTR_T_AGG_STS_E6399B4A COVERGROUPS -----------------------*/
    covergroup sha3_reg__global_intr_t_agg_sts_e6399b4a_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__global_intr_t_agg_sts_e6399b4a_fld_cg with function sample(
    input bit [1-1:0] agg_sts
    );
        option.per_instance = 1;
        agg_sts_cp : coverpoint agg_sts;

    endgroup

    /*----------------------- SHA3_REG__ERROR_INTR_T_ERROR1_STS_40E0D3E1_ERROR2_STS_B1CF2205_ERROR3_STS_74A35378_SHA3_ERROR_STS_A3CFDCF2 COVERGROUPS -----------------------*/
    covergroup sha3_reg__error_intr_t_error1_sts_40e0d3e1_error2_sts_b1cf2205_error3_sts_74a35378_sha3_error_sts_a3cfdcf2_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__error_intr_t_error1_sts_40e0d3e1_error2_sts_b1cf2205_error3_sts_74a35378_sha3_error_sts_a3cfdcf2_fld_cg with function sample(
    input bit [1-1:0] sha3_error_sts,
    input bit [1-1:0] error1_sts,
    input bit [1-1:0] error2_sts,
    input bit [1-1:0] error3_sts
    );
        option.per_instance = 1;
        sha3_error_sts_cp : coverpoint sha3_error_sts;
        error1_sts_cp : coverpoint error1_sts;
        error2_sts_cp : coverpoint error2_sts;
        error3_sts_cp : coverpoint error3_sts;

    endgroup

    /*----------------------- SHA3_REG__NOTIF_INTR_T_NOTIF_CMD_DONE_STS_1C68637E_NOTIF_MSG_FIFO_EMPTY_STS_DF694E73 COVERGROUPS -----------------------*/
    covergroup sha3_reg__notif_intr_t_notif_cmd_done_sts_1c68637e_notif_msg_fifo_empty_sts_df694e73_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__notif_intr_t_notif_cmd_done_sts_1c68637e_notif_msg_fifo_empty_sts_df694e73_fld_cg with function sample(
    input bit [1-1:0] notif_cmd_done_sts,
    input bit [1-1:0] notif_msg_fifo_empty_sts
    );
        option.per_instance = 1;
        notif_cmd_done_sts_cp : coverpoint notif_cmd_done_sts;
        notif_msg_fifo_empty_sts_cp : coverpoint notif_msg_fifo_empty_sts;

    endgroup

    /*----------------------- SHA3_REG__ERROR_INTR_TRIG_T COVERGROUPS -----------------------*/
    covergroup sha3_reg__error_intr_trig_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__error_intr_trig_t_fld_cg with function sample(
    input bit [1-1:0] sha3_error_trig,
    input bit [1-1:0] error1_trig,
    input bit [1-1:0] error2_trig,
    input bit [1-1:0] error3_trig
    );
        option.per_instance = 1;
        sha3_error_trig_cp : coverpoint sha3_error_trig;
        error1_trig_cp : coverpoint error1_trig;
        error2_trig_cp : coverpoint error2_trig;
        error3_trig_cp : coverpoint error3_trig;

    endgroup

    /*----------------------- SHA3_REG__NOTIF_INTR_TRIG_T COVERGROUPS -----------------------*/
    covergroup sha3_reg__notif_intr_trig_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__notif_intr_trig_t_fld_cg with function sample(
    input bit [1-1:0] notif_cmd_done_trig,
    input bit [1-1:0] notif_msg_fifo_empty_trig
    );
        option.per_instance = 1;
        notif_cmd_done_trig_cp : coverpoint notif_cmd_done_trig;
        notif_msg_fifo_empty_trig_cp : coverpoint notif_msg_fifo_empty_trig;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_9198FA18 COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_t_cnt_9198fa18_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_t_cnt_9198fa18_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_73C42C28 COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_t_cnt_73c42c28_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_t_cnt_73c42c28_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_D8AF96FF COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_t_cnt_d8af96ff_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_t_cnt_d8af96ff_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_9BD7F809 COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_t_cnt_9bd7f809_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_t_cnt_9bd7f809_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_T_CNT_BE67D6D5 COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_t_cnt_be67d6d5_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_t_cnt_be67d6d5_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_D65B5E88 COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_incr_t_pulse_d65b5e88_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_incr_t_pulse_d65b5e88_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_D860D977 COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_incr_t_pulse_d860d977_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_incr_t_pulse_d860d977_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_87B45FE7 COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_incr_t_pulse_87b45fe7_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_incr_t_pulse_87b45fe7_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_C1689EE6 COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_incr_t_pulse_c1689ee6_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_incr_t_pulse_c1689ee6_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

    /*----------------------- SHA3_REG__INTR_COUNT_INCR_T_PULSE_6173128E COVERGROUPS -----------------------*/
    covergroup sha3_reg__intr_count_incr_t_pulse_6173128e_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup sha3_reg__intr_count_incr_t_pulse_6173128e_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

`endif