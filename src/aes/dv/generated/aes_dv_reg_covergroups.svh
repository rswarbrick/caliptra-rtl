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

`ifndef AES_DV_REG_COVERGROUPS
    `define AES_DV_REG_COVERGROUPS
    
    /*----------------------- AES__KEY_SHARE0 COVERGROUPS -----------------------*/
    covergroup aes__KEY_SHARE0_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__KEY_SHARE0_fld_cg with function sample(
    input bit [32-1:0] KEY_SHARE0
    );
        option.per_instance = 1;
        KEY_SHARE0_cp : coverpoint KEY_SHARE0;

    endgroup

    /*----------------------- AES__KEY_SHARE1 COVERGROUPS -----------------------*/
    covergroup aes__KEY_SHARE1_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__KEY_SHARE1_fld_cg with function sample(
    input bit [32-1:0] KEY_SHARE1
    );
        option.per_instance = 1;
        KEY_SHARE1_cp : coverpoint KEY_SHARE1;

    endgroup

    /*----------------------- AES__IV COVERGROUPS -----------------------*/
    covergroup aes__IV_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__IV_fld_cg with function sample(
    input bit [32-1:0] IV
    );
        option.per_instance = 1;
        IV_cp : coverpoint IV;

    endgroup

    /*----------------------- AES__DATA_IN COVERGROUPS -----------------------*/
    covergroup aes__DATA_IN_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__DATA_IN_fld_cg with function sample(
    input bit [32-1:0] DATA_IN
    );
        option.per_instance = 1;
        DATA_IN_cp : coverpoint DATA_IN;

    endgroup

    /*----------------------- AES__DATA_OUT COVERGROUPS -----------------------*/
    covergroup aes__DATA_OUT_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__DATA_OUT_fld_cg with function sample(
    input bit [32-1:0] DATA_OUT
    );
        option.per_instance = 1;
        DATA_OUT_cp : coverpoint DATA_OUT;

    endgroup

    /*----------------------- AES__CTRL_SHADOWED COVERGROUPS -----------------------*/
    covergroup aes__CTRL_SHADOWED_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__CTRL_SHADOWED_fld_cg with function sample(
    input bit [2-1:0] OPERATION,
    input bit [6-1:0] MODE,
    input bit [3-1:0] KEY_LEN,
    input bit [1-1:0] SIDELOAD,
    input bit [3-1:0] PRNG_RESEED_RATE,
    input bit [1-1:0] MANUAL_OPERATION
    );
        option.per_instance = 1;
        OPERATION_cp : coverpoint OPERATION;
        MODE_cp : coverpoint MODE;
        KEY_LEN_cp : coverpoint KEY_LEN;
        SIDELOAD_cp : coverpoint SIDELOAD;
        PRNG_RESEED_RATE_cp : coverpoint PRNG_RESEED_RATE;
        MANUAL_OPERATION_cp : coverpoint MANUAL_OPERATION;

    endgroup

    /*----------------------- AES__CTRL_AUX_SHADOWED COVERGROUPS -----------------------*/
    covergroup aes__CTRL_AUX_SHADOWED_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__CTRL_AUX_SHADOWED_fld_cg with function sample(
    input bit [1-1:0] KEY_TOUCH_FORCES_RESEED,
    input bit [1-1:0] FORCE_MASKS
    );
        option.per_instance = 1;
        KEY_TOUCH_FORCES_RESEED_cp : coverpoint KEY_TOUCH_FORCES_RESEED;
        FORCE_MASKS_cp : coverpoint FORCE_MASKS;

    endgroup

    /*----------------------- AES__CTRL_AUX_REGWEN COVERGROUPS -----------------------*/
    covergroup aes__CTRL_AUX_REGWEN_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__CTRL_AUX_REGWEN_fld_cg with function sample(
    input bit [1-1:0] CTRL_AUX_REGWEN
    );
        option.per_instance = 1;
        CTRL_AUX_REGWEN_cp : coverpoint CTRL_AUX_REGWEN;

    endgroup

    /*----------------------- AES__TRIGGER COVERGROUPS -----------------------*/
    covergroup aes__TRIGGER_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__TRIGGER_fld_cg with function sample(
    input bit [1-1:0] START,
    input bit [1-1:0] KEY_IV_DATA_IN_CLEAR,
    input bit [1-1:0] DATA_OUT_CLEAR,
    input bit [1-1:0] PRNG_RESEED
    );
        option.per_instance = 1;
        START_cp : coverpoint START;
        KEY_IV_DATA_IN_CLEAR_cp : coverpoint KEY_IV_DATA_IN_CLEAR;
        DATA_OUT_CLEAR_cp : coverpoint DATA_OUT_CLEAR;
        PRNG_RESEED_cp : coverpoint PRNG_RESEED;

    endgroup

    /*----------------------- AES__STATUS COVERGROUPS -----------------------*/
    covergroup aes__STATUS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__STATUS_fld_cg with function sample(
    input bit [1-1:0] IDLE,
    input bit [1-1:0] STALL,
    input bit [1-1:0] OUTPUT_LOST,
    input bit [1-1:0] OUTPUT_VALID,
    input bit [1-1:0] INPUT_READY,
    input bit [1-1:0] ALERT_RECOV_CTRL_UPDATE_ERR,
    input bit [1-1:0] ALERT_FATAL_FAULT
    );
        option.per_instance = 1;
        IDLE_cp : coverpoint IDLE;
        STALL_cp : coverpoint STALL;
        OUTPUT_LOST_cp : coverpoint OUTPUT_LOST;
        OUTPUT_VALID_cp : coverpoint OUTPUT_VALID;
        INPUT_READY_cp : coverpoint INPUT_READY;
        ALERT_RECOV_CTRL_UPDATE_ERR_cp : coverpoint ALERT_RECOV_CTRL_UPDATE_ERR;
        ALERT_FATAL_FAULT_cp : coverpoint ALERT_FATAL_FAULT;

    endgroup

    /*----------------------- AES__CTRL_GCM_SHADOWED COVERGROUPS -----------------------*/
    covergroup aes__CTRL_GCM_SHADOWED_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes__CTRL_GCM_SHADOWED_fld_cg with function sample(
    input bit [6-1:0] PHASE,
    input bit [5-1:0] NUM_VALID_BYTES
    );
        option.per_instance = 1;
        PHASE_cp : coverpoint PHASE;
        NUM_VALID_BYTES_cp : coverpoint NUM_VALID_BYTES;

    endgroup

    /*----------------------- AES_CLP_REG__AES_NAME COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__AES_NAME_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__AES_NAME_fld_cg with function sample(
    input bit [32-1:0] NAME
    );
        option.per_instance = 1;
        NAME_cp : coverpoint NAME;

    endgroup

    /*----------------------- AES_CLP_REG__AES_VERSION COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__AES_VERSION_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__AES_VERSION_fld_cg with function sample(
    input bit [32-1:0] VERSION
    );
        option.per_instance = 1;
        VERSION_cp : coverpoint VERSION;

    endgroup

    /*----------------------- AES_CLP_REG__ENTROPY_IF_SEED COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__ENTROPY_IF_SEED_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__ENTROPY_IF_SEED_fld_cg with function sample(
    input bit [32-1:0] ENTROPY_IF_SEED
    );
        option.per_instance = 1;
        ENTROPY_IF_SEED_cp : coverpoint ENTROPY_IF_SEED;

    endgroup

    /*----------------------- AES_CLP_REG__CTRL0 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__CTRL0_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__CTRL0_fld_cg with function sample(
    input bit [1-1:0] ENDIAN_SWAP
    );
        option.per_instance = 1;
        ENDIAN_SWAP_cp : coverpoint ENDIAN_SWAP;

    endgroup

    /*----------------------- KV_READ_CTRL_REG COVERGROUPS -----------------------*/
    covergroup kv_read_ctrl_reg_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kv_read_ctrl_reg_fld_cg with function sample(
    input bit [1-1:0] read_en,
    input bit [5-1:0] read_entry,
    input bit [1-1:0] pcr_hash_extend,
    input bit [25-1:0] rsvd
    );
        option.per_instance = 1;
        read_en_cp : coverpoint read_en;
        read_entry_cp : coverpoint read_entry;
        pcr_hash_extend_cp : coverpoint pcr_hash_extend;
        rsvd_cp : coverpoint rsvd;

    endgroup

    /*----------------------- KV_STATUS_REG COVERGROUPS -----------------------*/
    covergroup kv_status_reg_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kv_status_reg_fld_cg with function sample(
    input bit [1-1:0] READY,
    input bit [1-1:0] VALID,
    input bit [8-1:0] ERROR
    );
        option.per_instance = 1;
        READY_cp : coverpoint READY;
        VALID_cp : coverpoint VALID;
        ERROR_cp : coverpoint ERROR;

    endgroup

    /*----------------------- KV_WRITE_CTRL_REG COVERGROUPS -----------------------*/
    covergroup kv_write_ctrl_reg_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup kv_write_ctrl_reg_fld_cg with function sample(
    input bit [1-1:0] write_en,
    input bit [5-1:0] write_entry,
    input bit [1-1:0] hmac_key_dest_valid,
    input bit [1-1:0] hmac_block_dest_valid,
    input bit [1-1:0] mldsa_seed_dest_valid,
    input bit [1-1:0] ecc_pkey_dest_valid,
    input bit [1-1:0] ecc_seed_dest_valid,
    input bit [1-1:0] aes_key_dest_valid,
    input bit [1-1:0] mlkem_seed_dest_valid,
    input bit [1-1:0] mlkem_msg_dest_valid,
    input bit [1-1:0] dma_data_dest_valid,
    input bit [17-1:0] rsvd
    );
        option.per_instance = 1;
        write_en_cp : coverpoint write_en;
        write_entry_cp : coverpoint write_entry;
        hmac_key_dest_valid_cp : coverpoint hmac_key_dest_valid;
        hmac_block_dest_valid_cp : coverpoint hmac_block_dest_valid;
        mldsa_seed_dest_valid_cp : coverpoint mldsa_seed_dest_valid;
        ecc_pkey_dest_valid_cp : coverpoint ecc_pkey_dest_valid;
        ecc_seed_dest_valid_cp : coverpoint ecc_seed_dest_valid;
        aes_key_dest_valid_cp : coverpoint aes_key_dest_valid;
        mlkem_seed_dest_valid_cp : coverpoint mlkem_seed_dest_valid;
        mlkem_msg_dest_valid_cp : coverpoint mlkem_msg_dest_valid;
        dma_data_dest_valid_cp : coverpoint dma_data_dest_valid;
        rsvd_cp : coverpoint rsvd;

    endgroup

    /*----------------------- AES_CLP_REG__GLOBAL_INTR_EN_T COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__global_intr_en_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__global_intr_en_t_fld_cg with function sample(
    input bit [1-1:0] error_en,
    input bit [1-1:0] notif_en
    );
        option.per_instance = 1;
        error_en_cp : coverpoint error_en;
        notif_en_cp : coverpoint notif_en;

    endgroup

    /*----------------------- AES_CLP_REG__ERROR_INTR_EN_T COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__error_intr_en_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__error_intr_en_t_fld_cg with function sample(
    input bit [1-1:0] error0_en,
    input bit [1-1:0] error1_en,
    input bit [1-1:0] error2_en,
    input bit [1-1:0] error3_en
    );
        option.per_instance = 1;
        error0_en_cp : coverpoint error0_en;
        error1_en_cp : coverpoint error1_en;
        error2_en_cp : coverpoint error2_en;
        error3_en_cp : coverpoint error3_en;

    endgroup

    /*----------------------- AES_CLP_REG__NOTIF_INTR_EN_T COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__notif_intr_en_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__notif_intr_en_t_fld_cg with function sample(
    input bit [1-1:0] notif_cmd_done_en
    );
        option.per_instance = 1;
        notif_cmd_done_en_cp : coverpoint notif_cmd_done_en;

    endgroup

    /*----------------------- AES_CLP_REG__GLOBAL_INTR_T_AGG_STS_DD3DCF0A COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__global_intr_t_agg_sts_dd3dcf0a_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__global_intr_t_agg_sts_dd3dcf0a_fld_cg with function sample(
    input bit [1-1:0] agg_sts
    );
        option.per_instance = 1;
        agg_sts_cp : coverpoint agg_sts;

    endgroup

    /*----------------------- AES_CLP_REG__GLOBAL_INTR_T_AGG_STS_E6399B4A COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__global_intr_t_agg_sts_e6399b4a_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__global_intr_t_agg_sts_e6399b4a_fld_cg with function sample(
    input bit [1-1:0] agg_sts
    );
        option.per_instance = 1;
        agg_sts_cp : coverpoint agg_sts;

    endgroup

    /*----------------------- AES_CLP_REG__ERROR_INTR_T_ERROR0_STS_28545624_ERROR1_STS_40E0D3E1_ERROR2_STS_B1CF2205_ERROR3_STS_74A35378 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__error_intr_t_error0_sts_28545624_error1_sts_40e0d3e1_error2_sts_b1cf2205_error3_sts_74a35378_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__error_intr_t_error0_sts_28545624_error1_sts_40e0d3e1_error2_sts_b1cf2205_error3_sts_74a35378_fld_cg with function sample(
    input bit [1-1:0] error0_sts,
    input bit [1-1:0] error1_sts,
    input bit [1-1:0] error2_sts,
    input bit [1-1:0] error3_sts
    );
        option.per_instance = 1;
        error0_sts_cp : coverpoint error0_sts;
        error1_sts_cp : coverpoint error1_sts;
        error2_sts_cp : coverpoint error2_sts;
        error3_sts_cp : coverpoint error3_sts;

    endgroup

    /*----------------------- AES_CLP_REG__NOTIF_INTR_T_NOTIF_CMD_DONE_STS_1C68637E COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__notif_intr_t_notif_cmd_done_sts_1c68637e_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__notif_intr_t_notif_cmd_done_sts_1c68637e_fld_cg with function sample(
    input bit [1-1:0] notif_cmd_done_sts
    );
        option.per_instance = 1;
        notif_cmd_done_sts_cp : coverpoint notif_cmd_done_sts;

    endgroup

    /*----------------------- AES_CLP_REG__ERROR_INTR_TRIG_T COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__error_intr_trig_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__error_intr_trig_t_fld_cg with function sample(
    input bit [1-1:0] error0_trig,
    input bit [1-1:0] error1_trig,
    input bit [1-1:0] error2_trig,
    input bit [1-1:0] error3_trig
    );
        option.per_instance = 1;
        error0_trig_cp : coverpoint error0_trig;
        error1_trig_cp : coverpoint error1_trig;
        error2_trig_cp : coverpoint error2_trig;
        error3_trig_cp : coverpoint error3_trig;

    endgroup

    /*----------------------- AES_CLP_REG__NOTIF_INTR_TRIG_T COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__notif_intr_trig_t_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__notif_intr_trig_t_fld_cg with function sample(
    input bit [1-1:0] notif_cmd_done_trig
    );
        option.per_instance = 1;
        notif_cmd_done_trig_cp : coverpoint notif_cmd_done_trig;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_35ACE267 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_t_cnt_35ace267_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_t_cnt_35ace267_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_73C42C28 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_t_cnt_73c42c28_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_t_cnt_73c42c28_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_D8AF96FF COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_t_cnt_d8af96ff_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_t_cnt_d8af96ff_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_9BD7F809 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_t_cnt_9bd7f809_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_t_cnt_9bd7f809_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_T_CNT_BE67D6D5 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_t_cnt_be67d6d5_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_t_cnt_be67d6d5_fld_cg with function sample(
    input bit [32-1:0] cnt
    );
        option.per_instance = 1;
        cnt_cp : coverpoint cnt;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_37026C97 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_incr_t_pulse_37026c97_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_incr_t_pulse_37026c97_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_D860D977 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_incr_t_pulse_d860d977_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_incr_t_pulse_d860d977_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_87B45FE7 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_incr_t_pulse_87b45fe7_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_incr_t_pulse_87b45fe7_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_C1689EE6 COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_incr_t_pulse_c1689ee6_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_incr_t_pulse_c1689ee6_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

    /*----------------------- AES_CLP_REG__INTR_COUNT_INCR_T_PULSE_6173128E COVERGROUPS -----------------------*/
    covergroup aes_clp_reg__intr_count_incr_t_pulse_6173128e_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup aes_clp_reg__intr_count_incr_t_pulse_6173128e_fld_cg with function sample(
    input bit [1-1:0] pulse
    );
        option.per_instance = 1;
        pulse_cp : coverpoint pulse;

    endgroup

`endif