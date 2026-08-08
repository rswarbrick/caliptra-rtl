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

`ifndef ENTROPY_SRC_COVERGROUPS
    `define ENTROPY_SRC_COVERGROUPS
    
    /*----------------------- ENTROPY_SRC__INTERRUPT_STATE COVERGROUPS -----------------------*/
    covergroup entropy_src__INTERRUPT_STATE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__INTERRUPT_STATE_fld_cg with function sample(
    input bit [1-1:0] ES_ENTROPY_VALID,
    input bit [1-1:0] ES_HEALTH_TEST_FAILED,
    input bit [1-1:0] ES_OBSERVE_FIFO_READY,
    input bit [1-1:0] ES_FATAL_ERR
    );
        option.per_instance = 1;
        ES_ENTROPY_VALID_cp : coverpoint ES_ENTROPY_VALID;
        ES_HEALTH_TEST_FAILED_cp : coverpoint ES_HEALTH_TEST_FAILED;
        ES_OBSERVE_FIFO_READY_cp : coverpoint ES_OBSERVE_FIFO_READY;
        ES_FATAL_ERR_cp : coverpoint ES_FATAL_ERR;

    endgroup

    /*----------------------- ENTROPY_SRC__INTERRUPT_ENABLE COVERGROUPS -----------------------*/
    covergroup entropy_src__INTERRUPT_ENABLE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__INTERRUPT_ENABLE_fld_cg with function sample(
    input bit [1-1:0] ES_ENTROPY_VALID,
    input bit [1-1:0] ES_HEALTH_TEST_FAILED,
    input bit [1-1:0] ES_OBSERVE_FIFO_READY,
    input bit [1-1:0] ES_FATAL_ERR
    );
        option.per_instance = 1;
        ES_ENTROPY_VALID_cp : coverpoint ES_ENTROPY_VALID;
        ES_HEALTH_TEST_FAILED_cp : coverpoint ES_HEALTH_TEST_FAILED;
        ES_OBSERVE_FIFO_READY_cp : coverpoint ES_OBSERVE_FIFO_READY;
        ES_FATAL_ERR_cp : coverpoint ES_FATAL_ERR;

    endgroup

    /*----------------------- ENTROPY_SRC__INTERRUPT_TEST COVERGROUPS -----------------------*/
    covergroup entropy_src__INTERRUPT_TEST_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__INTERRUPT_TEST_fld_cg with function sample(
    input bit [1-1:0] ES_ENTROPY_VALID,
    input bit [1-1:0] ES_HEALTH_TEST_FAILED,
    input bit [1-1:0] ES_OBSERVE_FIFO_READY,
    input bit [1-1:0] ES_FATAL_ERR
    );
        option.per_instance = 1;
        ES_ENTROPY_VALID_cp : coverpoint ES_ENTROPY_VALID;
        ES_HEALTH_TEST_FAILED_cp : coverpoint ES_HEALTH_TEST_FAILED;
        ES_OBSERVE_FIFO_READY_cp : coverpoint ES_OBSERVE_FIFO_READY;
        ES_FATAL_ERR_cp : coverpoint ES_FATAL_ERR;

    endgroup

    /*----------------------- ENTROPY_SRC__ALERT_TEST COVERGROUPS -----------------------*/
    covergroup entropy_src__ALERT_TEST_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ALERT_TEST_fld_cg with function sample(
    input bit [1-1:0] RECOV_ALERT,
    input bit [1-1:0] FATAL_ALERT
    );
        option.per_instance = 1;
        RECOV_ALERT_cp : coverpoint RECOV_ALERT;
        FATAL_ALERT_cp : coverpoint FATAL_ALERT;

    endgroup

    /*----------------------- ENTROPY_SRC__ME_REGWEN COVERGROUPS -----------------------*/
    covergroup entropy_src__ME_REGWEN_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ME_REGWEN_fld_cg with function sample(
    input bit [1-1:0] ME_REGWEN
    );
        option.per_instance = 1;
        ME_REGWEN_cp : coverpoint ME_REGWEN;

    endgroup

    /*----------------------- ENTROPY_SRC__SW_REGUPD COVERGROUPS -----------------------*/
    covergroup entropy_src__SW_REGUPD_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__SW_REGUPD_fld_cg with function sample(
    input bit [1-1:0] SW_REGUPD
    );
        option.per_instance = 1;
        SW_REGUPD_cp : coverpoint SW_REGUPD;

    endgroup

    /*----------------------- ENTROPY_SRC__REGWEN COVERGROUPS -----------------------*/
    covergroup entropy_src__REGWEN_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__REGWEN_fld_cg with function sample(
    input bit [1-1:0] REGWEN
    );
        option.per_instance = 1;
        REGWEN_cp : coverpoint REGWEN;

    endgroup

    /*----------------------- ENTROPY_SRC__REV COVERGROUPS -----------------------*/
    covergroup entropy_src__REV_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__REV_fld_cg with function sample(
    input bit [8-1:0] ABI_REVISION,
    input bit [8-1:0] HW_REVISION,
    input bit [8-1:0] CHIP_TYPE
    );
        option.per_instance = 1;
        ABI_REVISION_cp : coverpoint ABI_REVISION;
        HW_REVISION_cp : coverpoint HW_REVISION;
        CHIP_TYPE_cp : coverpoint CHIP_TYPE;

    endgroup

    /*----------------------- ENTROPY_SRC__MODULE_ENABLE COVERGROUPS -----------------------*/
    covergroup entropy_src__MODULE_ENABLE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__MODULE_ENABLE_fld_cg with function sample(
    input bit [4-1:0] MODULE_ENABLE
    );
        option.per_instance = 1;
        MODULE_ENABLE_cp : coverpoint MODULE_ENABLE;

    endgroup

    /*----------------------- ENTROPY_SRC__CONF COVERGROUPS -----------------------*/
    covergroup entropy_src__CONF_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__CONF_fld_cg with function sample(
    input bit [4-1:0] FIPS_ENABLE,
    input bit [4-1:0] FIPS_FLAG,
    input bit [4-1:0] RNG_FIPS,
    input bit [4-1:0] RNG_BIT_ENABLE,
    input bit [2-1:0] RNG_BIT_SEL,
    input bit [4-1:0] THRESHOLD_SCOPE,
    input bit [4-1:0] ENTROPY_DATA_REG_ENABLE
    );
        option.per_instance = 1;
        FIPS_ENABLE_cp : coverpoint FIPS_ENABLE;
        FIPS_FLAG_cp : coverpoint FIPS_FLAG;
        RNG_FIPS_cp : coverpoint RNG_FIPS;
        RNG_BIT_ENABLE_cp : coverpoint RNG_BIT_ENABLE;
        RNG_BIT_SEL_cp : coverpoint RNG_BIT_SEL;
        THRESHOLD_SCOPE_cp : coverpoint THRESHOLD_SCOPE;
        ENTROPY_DATA_REG_ENABLE_cp : coverpoint ENTROPY_DATA_REG_ENABLE;

    endgroup

    /*----------------------- ENTROPY_SRC__ENTROPY_CONTROL COVERGROUPS -----------------------*/
    covergroup entropy_src__ENTROPY_CONTROL_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ENTROPY_CONTROL_fld_cg with function sample(
    input bit [4-1:0] ES_ROUTE,
    input bit [4-1:0] ES_TYPE
    );
        option.per_instance = 1;
        ES_ROUTE_cp : coverpoint ES_ROUTE;
        ES_TYPE_cp : coverpoint ES_TYPE;

    endgroup

    /*----------------------- ENTROPY_SRC__ENTROPY_DATA COVERGROUPS -----------------------*/
    covergroup entropy_src__ENTROPY_DATA_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ENTROPY_DATA_fld_cg with function sample(
    input bit [32-1:0] ENTROPY_DATA
    );
        option.per_instance = 1;
        ENTROPY_DATA_cp : coverpoint ENTROPY_DATA;

    endgroup

    /*----------------------- ENTROPY_SRC__HEALTH_TEST_WINDOWS COVERGROUPS -----------------------*/
    covergroup entropy_src__HEALTH_TEST_WINDOWS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__HEALTH_TEST_WINDOWS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WINDOW,
    input bit [16-1:0] BYPASS_WINDOW
    );
        option.per_instance = 1;
        FIPS_WINDOW_cp : coverpoint FIPS_WINDOW;
        BYPASS_WINDOW_cp : coverpoint BYPASS_WINDOW;

    endgroup

    /*----------------------- ENTROPY_SRC__REPCNT_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__REPCNT_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__REPCNT_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__REPCNTS_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__REPCNTS_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__REPCNTS_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__ADAPTP_HI_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__ADAPTP_HI_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ADAPTP_HI_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__ADAPTP_LO_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__ADAPTP_LO_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ADAPTP_LO_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__BUCKET_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__BUCKET_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__BUCKET_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__MARKOV_HI_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__MARKOV_HI_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__MARKOV_HI_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__MARKOV_LO_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__MARKOV_LO_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__MARKOV_LO_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__EXTHT_HI_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__EXTHT_HI_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__EXTHT_HI_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__EXTHT_LO_THRESHOLDS COVERGROUPS -----------------------*/
    covergroup entropy_src__EXTHT_LO_THRESHOLDS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__EXTHT_LO_THRESHOLDS_fld_cg with function sample(
    input bit [16-1:0] FIPS_THRESH,
    input bit [16-1:0] BYPASS_THRESH
    );
        option.per_instance = 1;
        FIPS_THRESH_cp : coverpoint FIPS_THRESH;
        BYPASS_THRESH_cp : coverpoint BYPASS_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__REPCNT_HI_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__REPCNT_HI_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__REPCNT_HI_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__REPCNTS_HI_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__REPCNTS_HI_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__REPCNTS_HI_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__ADAPTP_HI_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__ADAPTP_HI_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ADAPTP_HI_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__ADAPTP_LO_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__ADAPTP_LO_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ADAPTP_LO_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__EXTHT_HI_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__EXTHT_HI_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__EXTHT_HI_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__EXTHT_LO_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__EXTHT_LO_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__EXTHT_LO_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__BUCKET_HI_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__BUCKET_HI_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__BUCKET_HI_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__MARKOV_HI_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__MARKOV_HI_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__MARKOV_HI_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__MARKOV_LO_WATERMARKS COVERGROUPS -----------------------*/
    covergroup entropy_src__MARKOV_LO_WATERMARKS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__MARKOV_LO_WATERMARKS_fld_cg with function sample(
    input bit [16-1:0] FIPS_WATERMARK,
    input bit [16-1:0] BYPASS_WATERMARK
    );
        option.per_instance = 1;
        FIPS_WATERMARK_cp : coverpoint FIPS_WATERMARK;
        BYPASS_WATERMARK_cp : coverpoint BYPASS_WATERMARK;

    endgroup

    /*----------------------- ENTROPY_SRC__REPCNT_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__REPCNT_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__REPCNT_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] REPCNT_TOTAL_FAILS
    );
        option.per_instance = 1;
        REPCNT_TOTAL_FAILS_cp : coverpoint REPCNT_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__REPCNTS_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__REPCNTS_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__REPCNTS_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] REPCNTS_TOTAL_FAILS
    );
        option.per_instance = 1;
        REPCNTS_TOTAL_FAILS_cp : coverpoint REPCNTS_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__ADAPTP_HI_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__ADAPTP_HI_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ADAPTP_HI_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] ADAPTP_HI_TOTAL_FAILS
    );
        option.per_instance = 1;
        ADAPTP_HI_TOTAL_FAILS_cp : coverpoint ADAPTP_HI_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__ADAPTP_LO_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__ADAPTP_LO_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ADAPTP_LO_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] ADAPTP_LO_TOTAL_FAILS
    );
        option.per_instance = 1;
        ADAPTP_LO_TOTAL_FAILS_cp : coverpoint ADAPTP_LO_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__BUCKET_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__BUCKET_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__BUCKET_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] BUCKET_TOTAL_FAILS
    );
        option.per_instance = 1;
        BUCKET_TOTAL_FAILS_cp : coverpoint BUCKET_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__MARKOV_HI_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__MARKOV_HI_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__MARKOV_HI_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] MARKOV_HI_TOTAL_FAILS
    );
        option.per_instance = 1;
        MARKOV_HI_TOTAL_FAILS_cp : coverpoint MARKOV_HI_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__MARKOV_LO_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__MARKOV_LO_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__MARKOV_LO_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] MARKOV_LO_TOTAL_FAILS
    );
        option.per_instance = 1;
        MARKOV_LO_TOTAL_FAILS_cp : coverpoint MARKOV_LO_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__EXTHT_HI_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__EXTHT_HI_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__EXTHT_HI_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] EXTHT_HI_TOTAL_FAILS
    );
        option.per_instance = 1;
        EXTHT_HI_TOTAL_FAILS_cp : coverpoint EXTHT_HI_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__EXTHT_LO_TOTAL_FAILS COVERGROUPS -----------------------*/
    covergroup entropy_src__EXTHT_LO_TOTAL_FAILS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__EXTHT_LO_TOTAL_FAILS_fld_cg with function sample(
    input bit [32-1:0] EXTHT_LO_TOTAL_FAILS
    );
        option.per_instance = 1;
        EXTHT_LO_TOTAL_FAILS_cp : coverpoint EXTHT_LO_TOTAL_FAILS;

    endgroup

    /*----------------------- ENTROPY_SRC__ALERT_THRESHOLD COVERGROUPS -----------------------*/
    covergroup entropy_src__ALERT_THRESHOLD_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ALERT_THRESHOLD_fld_cg with function sample(
    input bit [16-1:0] ALERT_THRESHOLD,
    input bit [16-1:0] ALERT_THRESHOLD_INV
    );
        option.per_instance = 1;
        ALERT_THRESHOLD_cp : coverpoint ALERT_THRESHOLD;
        ALERT_THRESHOLD_INV_cp : coverpoint ALERT_THRESHOLD_INV;

    endgroup

    /*----------------------- ENTROPY_SRC__ALERT_SUMMARY_FAIL_COUNTS COVERGROUPS -----------------------*/
    covergroup entropy_src__ALERT_SUMMARY_FAIL_COUNTS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ALERT_SUMMARY_FAIL_COUNTS_fld_cg with function sample(
    input bit [16-1:0] ANY_FAIL_COUNT
    );
        option.per_instance = 1;
        ANY_FAIL_COUNT_cp : coverpoint ANY_FAIL_COUNT;

    endgroup

    /*----------------------- ENTROPY_SRC__ALERT_FAIL_COUNTS COVERGROUPS -----------------------*/
    covergroup entropy_src__ALERT_FAIL_COUNTS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ALERT_FAIL_COUNTS_fld_cg with function sample(
    input bit [4-1:0] REPCNT_FAIL_COUNT,
    input bit [4-1:0] ADAPTP_HI_FAIL_COUNT,
    input bit [4-1:0] ADAPTP_LO_FAIL_COUNT,
    input bit [4-1:0] BUCKET_FAIL_COUNT,
    input bit [4-1:0] MARKOV_HI_FAIL_COUNT,
    input bit [4-1:0] MARKOV_LO_FAIL_COUNT,
    input bit [4-1:0] REPCNTS_FAIL_COUNT
    );
        option.per_instance = 1;
        REPCNT_FAIL_COUNT_cp : coverpoint REPCNT_FAIL_COUNT;
        ADAPTP_HI_FAIL_COUNT_cp : coverpoint ADAPTP_HI_FAIL_COUNT;
        ADAPTP_LO_FAIL_COUNT_cp : coverpoint ADAPTP_LO_FAIL_COUNT;
        BUCKET_FAIL_COUNT_cp : coverpoint BUCKET_FAIL_COUNT;
        MARKOV_HI_FAIL_COUNT_cp : coverpoint MARKOV_HI_FAIL_COUNT;
        MARKOV_LO_FAIL_COUNT_cp : coverpoint MARKOV_LO_FAIL_COUNT;
        REPCNTS_FAIL_COUNT_cp : coverpoint REPCNTS_FAIL_COUNT;

    endgroup

    /*----------------------- ENTROPY_SRC__EXTHT_FAIL_COUNTS COVERGROUPS -----------------------*/
    covergroup entropy_src__EXTHT_FAIL_COUNTS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__EXTHT_FAIL_COUNTS_fld_cg with function sample(
    input bit [4-1:0] EXTHT_HI_FAIL_COUNT,
    input bit [4-1:0] EXTHT_LO_FAIL_COUNT
    );
        option.per_instance = 1;
        EXTHT_HI_FAIL_COUNT_cp : coverpoint EXTHT_HI_FAIL_COUNT;
        EXTHT_LO_FAIL_COUNT_cp : coverpoint EXTHT_LO_FAIL_COUNT;

    endgroup

    /*----------------------- ENTROPY_SRC__FW_OV_CONTROL COVERGROUPS -----------------------*/
    covergroup entropy_src__FW_OV_CONTROL_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__FW_OV_CONTROL_fld_cg with function sample(
    input bit [4-1:0] FW_OV_MODE,
    input bit [4-1:0] FW_OV_ENTROPY_INSERT
    );
        option.per_instance = 1;
        FW_OV_MODE_cp : coverpoint FW_OV_MODE;
        FW_OV_ENTROPY_INSERT_cp : coverpoint FW_OV_ENTROPY_INSERT;

    endgroup

    /*----------------------- ENTROPY_SRC__FW_OV_SHA3_START COVERGROUPS -----------------------*/
    covergroup entropy_src__FW_OV_SHA3_START_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__FW_OV_SHA3_START_fld_cg with function sample(
    input bit [4-1:0] FW_OV_INSERT_START
    );
        option.per_instance = 1;
        FW_OV_INSERT_START_cp : coverpoint FW_OV_INSERT_START;

    endgroup

    /*----------------------- ENTROPY_SRC__FW_OV_WR_FIFO_FULL COVERGROUPS -----------------------*/
    covergroup entropy_src__FW_OV_WR_FIFO_FULL_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__FW_OV_WR_FIFO_FULL_fld_cg with function sample(
    input bit [1-1:0] FW_OV_WR_FIFO_FULL
    );
        option.per_instance = 1;
        FW_OV_WR_FIFO_FULL_cp : coverpoint FW_OV_WR_FIFO_FULL;

    endgroup

    /*----------------------- ENTROPY_SRC__FW_OV_RD_FIFO_OVERFLOW COVERGROUPS -----------------------*/
    covergroup entropy_src__FW_OV_RD_FIFO_OVERFLOW_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__FW_OV_RD_FIFO_OVERFLOW_fld_cg with function sample(
    input bit [1-1:0] FW_OV_RD_FIFO_OVERFLOW
    );
        option.per_instance = 1;
        FW_OV_RD_FIFO_OVERFLOW_cp : coverpoint FW_OV_RD_FIFO_OVERFLOW;

    endgroup

    /*----------------------- ENTROPY_SRC__FW_OV_RD_DATA COVERGROUPS -----------------------*/
    covergroup entropy_src__FW_OV_RD_DATA_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__FW_OV_RD_DATA_fld_cg with function sample(
    input bit [32-1:0] FW_OV_RD_DATA
    );
        option.per_instance = 1;
        FW_OV_RD_DATA_cp : coverpoint FW_OV_RD_DATA;

    endgroup

    /*----------------------- ENTROPY_SRC__FW_OV_WR_DATA COVERGROUPS -----------------------*/
    covergroup entropy_src__FW_OV_WR_DATA_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__FW_OV_WR_DATA_fld_cg with function sample(
    input bit [32-1:0] FW_OV_WR_DATA
    );
        option.per_instance = 1;
        FW_OV_WR_DATA_cp : coverpoint FW_OV_WR_DATA;

    endgroup

    /*----------------------- ENTROPY_SRC__OBSERVE_FIFO_THRESH COVERGROUPS -----------------------*/
    covergroup entropy_src__OBSERVE_FIFO_THRESH_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__OBSERVE_FIFO_THRESH_fld_cg with function sample(
    input bit [6-1:0] OBSERVE_FIFO_THRESH
    );
        option.per_instance = 1;
        OBSERVE_FIFO_THRESH_cp : coverpoint OBSERVE_FIFO_THRESH;

    endgroup

    /*----------------------- ENTROPY_SRC__OBSERVE_FIFO_DEPTH COVERGROUPS -----------------------*/
    covergroup entropy_src__OBSERVE_FIFO_DEPTH_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__OBSERVE_FIFO_DEPTH_fld_cg with function sample(
    input bit [6-1:0] OBSERVE_FIFO_DEPTH
    );
        option.per_instance = 1;
        OBSERVE_FIFO_DEPTH_cp : coverpoint OBSERVE_FIFO_DEPTH;

    endgroup

    /*----------------------- ENTROPY_SRC__DEBUG_STATUS COVERGROUPS -----------------------*/
    covergroup entropy_src__DEBUG_STATUS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__DEBUG_STATUS_fld_cg with function sample(
    input bit [2-1:0] ENTROPY_FIFO_DEPTH,
    input bit [3-1:0] SHA3_FSM,
    input bit [1-1:0] SHA3_BLOCK_PR,
    input bit [1-1:0] SHA3_SQUEEZING,
    input bit [1-1:0] SHA3_ABSORBED,
    input bit [1-1:0] SHA3_ERR,
    input bit [1-1:0] MAIN_SM_IDLE,
    input bit [1-1:0] MAIN_SM_BOOT_DONE
    );
        option.per_instance = 1;
        ENTROPY_FIFO_DEPTH_cp : coverpoint ENTROPY_FIFO_DEPTH;
        SHA3_FSM_cp : coverpoint SHA3_FSM;
        SHA3_BLOCK_PR_cp : coverpoint SHA3_BLOCK_PR;
        SHA3_SQUEEZING_cp : coverpoint SHA3_SQUEEZING;
        SHA3_ABSORBED_cp : coverpoint SHA3_ABSORBED;
        SHA3_ERR_cp : coverpoint SHA3_ERR;
        MAIN_SM_IDLE_cp : coverpoint MAIN_SM_IDLE;
        MAIN_SM_BOOT_DONE_cp : coverpoint MAIN_SM_BOOT_DONE;

    endgroup

    /*----------------------- ENTROPY_SRC__RECOV_ALERT_STS COVERGROUPS -----------------------*/
    covergroup entropy_src__RECOV_ALERT_STS_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__RECOV_ALERT_STS_fld_cg with function sample(
    input bit [1-1:0] FIPS_ENABLE_FIELD_ALERT,
    input bit [1-1:0] ENTROPY_DATA_REG_EN_FIELD_ALERT,
    input bit [1-1:0] MODULE_ENABLE_FIELD_ALERT,
    input bit [1-1:0] THRESHOLD_SCOPE_FIELD_ALERT,
    input bit [1-1:0] RNG_BIT_ENABLE_FIELD_ALERT,
    input bit [1-1:0] FW_OV_SHA3_START_FIELD_ALERT,
    input bit [1-1:0] FW_OV_MODE_FIELD_ALERT,
    input bit [1-1:0] FW_OV_ENTROPY_INSERT_FIELD_ALERT,
    input bit [1-1:0] ES_ROUTE_FIELD_ALERT,
    input bit [1-1:0] ES_TYPE_FIELD_ALERT,
    input bit [1-1:0] ES_MAIN_SM_ALERT,
    input bit [1-1:0] ES_BUS_CMP_ALERT,
    input bit [1-1:0] ES_THRESH_CFG_ALERT,
    input bit [1-1:0] ES_FW_OV_WR_ALERT,
    input bit [1-1:0] ES_FW_OV_DISABLE_ALERT,
    input bit [1-1:0] FIPS_FLAG_FIELD_ALERT,
    input bit [1-1:0] RNG_FIPS_FIELD_ALERT,
    input bit [1-1:0] POSTHT_ENTROPY_DROP_ALERT
    );
        option.per_instance = 1;
        FIPS_ENABLE_FIELD_ALERT_cp : coverpoint FIPS_ENABLE_FIELD_ALERT;
        ENTROPY_DATA_REG_EN_FIELD_ALERT_cp : coverpoint ENTROPY_DATA_REG_EN_FIELD_ALERT;
        MODULE_ENABLE_FIELD_ALERT_cp : coverpoint MODULE_ENABLE_FIELD_ALERT;
        THRESHOLD_SCOPE_FIELD_ALERT_cp : coverpoint THRESHOLD_SCOPE_FIELD_ALERT;
        RNG_BIT_ENABLE_FIELD_ALERT_cp : coverpoint RNG_BIT_ENABLE_FIELD_ALERT;
        FW_OV_SHA3_START_FIELD_ALERT_cp : coverpoint FW_OV_SHA3_START_FIELD_ALERT;
        FW_OV_MODE_FIELD_ALERT_cp : coverpoint FW_OV_MODE_FIELD_ALERT;
        FW_OV_ENTROPY_INSERT_FIELD_ALERT_cp : coverpoint FW_OV_ENTROPY_INSERT_FIELD_ALERT;
        ES_ROUTE_FIELD_ALERT_cp : coverpoint ES_ROUTE_FIELD_ALERT;
        ES_TYPE_FIELD_ALERT_cp : coverpoint ES_TYPE_FIELD_ALERT;
        ES_MAIN_SM_ALERT_cp : coverpoint ES_MAIN_SM_ALERT;
        ES_BUS_CMP_ALERT_cp : coverpoint ES_BUS_CMP_ALERT;
        ES_THRESH_CFG_ALERT_cp : coverpoint ES_THRESH_CFG_ALERT;
        ES_FW_OV_WR_ALERT_cp : coverpoint ES_FW_OV_WR_ALERT;
        ES_FW_OV_DISABLE_ALERT_cp : coverpoint ES_FW_OV_DISABLE_ALERT;
        FIPS_FLAG_FIELD_ALERT_cp : coverpoint FIPS_FLAG_FIELD_ALERT;
        RNG_FIPS_FIELD_ALERT_cp : coverpoint RNG_FIPS_FIELD_ALERT;
        POSTHT_ENTROPY_DROP_ALERT_cp : coverpoint POSTHT_ENTROPY_DROP_ALERT;

    endgroup

    /*----------------------- ENTROPY_SRC__ERR_CODE COVERGROUPS -----------------------*/
    covergroup entropy_src__ERR_CODE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ERR_CODE_fld_cg with function sample(
    input bit [1-1:0] SFIFO_ESRNG_ERR,
    input bit [1-1:0] SFIFO_DISTR_ERR,
    input bit [1-1:0] SFIFO_OBSERVE_ERR,
    input bit [1-1:0] SFIFO_ESFINAL_ERR,
    input bit [1-1:0] ES_ACK_SM_ERR,
    input bit [1-1:0] ES_MAIN_SM_ERR,
    input bit [1-1:0] ES_CNTR_ERR,
    input bit [1-1:0] SHA3_STATE_ERR,
    input bit [1-1:0] SHA3_RST_STORAGE_ERR,
    input bit [1-1:0] FIFO_WRITE_ERR,
    input bit [1-1:0] FIFO_READ_ERR,
    input bit [1-1:0] FIFO_STATE_ERR
    );
        option.per_instance = 1;
        SFIFO_ESRNG_ERR_cp : coverpoint SFIFO_ESRNG_ERR;
        SFIFO_DISTR_ERR_cp : coverpoint SFIFO_DISTR_ERR;
        SFIFO_OBSERVE_ERR_cp : coverpoint SFIFO_OBSERVE_ERR;
        SFIFO_ESFINAL_ERR_cp : coverpoint SFIFO_ESFINAL_ERR;
        ES_ACK_SM_ERR_cp : coverpoint ES_ACK_SM_ERR;
        ES_MAIN_SM_ERR_cp : coverpoint ES_MAIN_SM_ERR;
        ES_CNTR_ERR_cp : coverpoint ES_CNTR_ERR;
        SHA3_STATE_ERR_cp : coverpoint SHA3_STATE_ERR;
        SHA3_RST_STORAGE_ERR_cp : coverpoint SHA3_RST_STORAGE_ERR;
        FIFO_WRITE_ERR_cp : coverpoint FIFO_WRITE_ERR;
        FIFO_READ_ERR_cp : coverpoint FIFO_READ_ERR;
        FIFO_STATE_ERR_cp : coverpoint FIFO_STATE_ERR;

    endgroup

    /*----------------------- ENTROPY_SRC__ERR_CODE_TEST COVERGROUPS -----------------------*/
    covergroup entropy_src__ERR_CODE_TEST_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__ERR_CODE_TEST_fld_cg with function sample(
    input bit [5-1:0] ERR_CODE_TEST
    );
        option.per_instance = 1;
        ERR_CODE_TEST_cp : coverpoint ERR_CODE_TEST;

    endgroup

    /*----------------------- ENTROPY_SRC__MAIN_SM_STATE COVERGROUPS -----------------------*/
    covergroup entropy_src__MAIN_SM_STATE_bit_cg with function sample(input bit reg_bit);
        option.per_instance = 1;
        reg_bit_cp : coverpoint reg_bit {
            bins value[2] = {0,1};
        }
        reg_bit_edge_cp : coverpoint reg_bit {
            bins rise = (0 => 1);
            bins fall = (1 => 0);
        }

    endgroup
    covergroup entropy_src__MAIN_SM_STATE_fld_cg with function sample(
    input bit [9-1:0] MAIN_SM_STATE
    );
        option.per_instance = 1;
        MAIN_SM_STATE_cp : coverpoint MAIN_SM_STATE;

    endgroup

`endif