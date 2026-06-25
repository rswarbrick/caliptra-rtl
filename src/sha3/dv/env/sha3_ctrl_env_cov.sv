// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

/**
 * Covergroups that are dependent on run-time parameters that may be available
 * only in build_phase can be defined here
 * Covergroups may also be wrapped inside helper classes if needed.
 */

// Covers various configuration combinations for the masked version of KMAC.
//
// Declare this outside of `sha3_ctrl_env_cov` so that we can conditionally instantiate this in the
// `build_phase` depending on a value in the env_cfg object.

// macro for the common KMAC configuration fields
`define COMMON_CFG_CGS \
    kmac_en:      coverpoint kmac; \
    xof_en:       coverpoint xof; \
    strength:     coverpoint kstrength; \
    mode:         coverpoint kmode; \
    key_len:      coverpoint key; \
    msg_endian:   coverpoint msg_endianness; \
    state_endian: coverpoint state_endianness; \

// creates the cross bins for all XOF functions
`define XOF_CROSS_CG(strength_cg, valid_mode_expr) \
      bins valid = ``valid_mode_expr`` && binsof(``strength_cg``) intersect {sha3_pkg::L128, sha3_pkg::L256}; \
      ignore_bins invalid_mode = !``valid_mode_expr``; \
      ignore_bins invalid_strength = !binsof(``strength_cg``) intersect {sha3_pkg::L128, sha3_pkg::L256};

// creates the cross bins for SHA3 functions
`define SHA3_CROSS_CG(mode_cg, strength_cg) \
    bins valid = binsof(``mode_cg``) intersect {sha3_pkg::Sha3}; \
    ignore_bins invalid_mode = !binsof(``mode_cg``) intersect {sha3_pkg::Sha3}; \
    ignore_bins invalid_strength = binsof(``strength_cg``) intersect {sha3_pkg::L128};

// creates a coverpoint to cover different TLUL access granularities
`define MASK_CP(name, mask) \
    ``name``: coverpoint ``mask`` { \
      bins byte_access        = {'b0001, 'b0010, 'b0100, 'b1000}; \
      bins halfword_access    = {'b0011, 'b0110, 'b1100}; \
      bins triple_byte_access = {'b0111, 'b1110}; \
      bins word_access        = {'b1111}; \
    }


covergroup config_masked_cg with function sample(bit kmac, bit xof,
                                                 sha3_pkg::keccak_strength_e kstrength,
                                                 sha3_pkg::sha3_mode_e kmode,
                                                 kmac_pkg::key_len_e key,
                                                 bit msg_endianness,
                                                 bit state_endianness,
                                                 kmac_pkg::entropy_mode_e entr_mode,
                                                 bit fast_entropy);
  `COMMON_CFG_CGS

  entropy_mode: coverpoint entr_mode;

  entropy_fast_process: coverpoint fast_entropy;

  // cross the various configuration settings

  kmac_cross: cross kmac_en, xof_en, strength, key_len, msg_endian,
                    state_endian, entropy_mode, entropy_fast_process {
    `XOF_CROSS_CG(strength, binsof(kmac_en) intersect {1})
  }

  cshake_cross: cross mode, strength, msg_endian, state_endian,
                               entropy_mode, entropy_fast_process {
    `XOF_CROSS_CG(strength, binsof(mode) intersect {sha3_pkg::CShake})
  }

  shake_cross: cross mode, strength, msg_endian, state_endian,
                              entropy_mode, entropy_fast_process {
    `XOF_CROSS_CG(strength, binsof(mode) intersect {sha3_pkg::Shake})
  }

  sha3_cross: cross mode, strength, msg_endian, state_endian,
                    entropy_mode, entropy_fast_process {
    `SHA3_CROSS_CG(mode, strength)
  }
endgroup


// Covers various configuration combinations for the unmasked version of KMAC.
//
// Declare this outside of `kmac_env_cov` so that we can conditionally instantiate this in the
// `build_phase` depending on a value in the env_cfg object.
covergroup config_unmasked_cg with function sample(bit kmac, bit xof,
                                                   sha3_pkg::keccak_strength_e kstrength,
                                                   sha3_pkg::sha3_mode_e kmode,
                                                   kmac_pkg::key_len_e key,
                                                   bit msg_endianness,
                                                   bit state_endianness);
  `COMMON_CFG_CGS

  // cross the various configuration settings

  kmac_cross: cross kmac_en, xof_en, strength, key_len, msg_endian, state_endian {
    `XOF_CROSS_CG(strength, binsof(kmac_en) intersect {1})
  }

  cshake_cross: cross mode, strength, msg_endian, state_endian {
    `XOF_CROSS_CG(strength, binsof(mode) intersect {sha3_pkg::CShake})
  }

  shake_cross: cross mode, strength, msg_endian, state_endian {
    `XOF_CROSS_CG(strength, binsof(mode) intersect {sha3_pkg::Shake})
  }

  sha3_cross: cross mode, strength, msg_endian, state_endian {
    `SHA3_CROSS_CG(mode, strength)
  }

endgroup

class sha3_ctrl_env_cov extends dv_base_env_cov #(.CFG_T(sha3_ctrl_env_cfg));
  `uvm_component_utils(sha3_ctrl_env_cov)

  // the base class provides the following handles for use:
  // sha3_ctrl_env_cfg: cfg

  // covergroups

  config_masked_cg config_masked_cg;
  config_unmasked_cg config_unmasked_cg;

  covergroup msg_len_cg with function sample(int len);
    msg_len: coverpoint len {
      bins len_0                    = {0};
      bins len_1                    = {1};
      bins len_keccak_block_sizes[] = {72, 104, 136, 144, 168};
      bins len_0_256                = {[0 : 256]};
      bins len_257_512              = {[257 : 512]};
      bins len_513_768              = {[513 : 768]};
      bins len_769_1024             = {[769 : 1024]};
      bins len_1025_2500            = {[1025 : 2500]};
      bins len_2501_5000            = {[2501 : 5000]};
      bins len_5001_7500            = {[5001 : 7500]};
      bins len_7501_10000           = {[7501 : 10_000]};
      bins remainder                = default;
    }
  endgroup

  covergroup output_digest_len_cg with function sample(int len);
    output_digest_len: coverpoint len {
      bins len_1                            = {1};
      bins len_2_63                         = {[2 : 63]};
      bins len_datapath_width               = {64};
      bins len_keccak_block_sizes[]         = {72, 104, 136, 144, 168};
      bins len_min_for_xof_require_squeeze  = {137, 169};
      bins len_65_200                       = {[65  : 200]};
      bins len_201_400                      = {[201 : 400]};
      bins len_401_600                      = {[401 : 600]};
      bins len_601_800                      = {[601 : 800]};
      bins len_801_1000                     = {[801 : 1_000]};
      bins remainder                        = default;
    }
  endgroup

  covergroup prefix_range_cg with function sample(byte b);
    prefix_range: coverpoint b {
      bins space              = {32};
      bins capital_letters    = {[65 : 90]};
      bins lowercase_letters  = {[97 : 122]};
      bins rest               = default;
    }
  endgroup

  covergroup msgfifo_level_cg with function sample(bit fifo_empty, bit fifo_full, bit [4:0] fifo_depth,
                                                   sha3_pkg::sha3_mode_e mode, bit kmac_en);
    kmac_mode: coverpoint kmac_en;
    hash_mode: coverpoint mode {
      bins sha3   = {sha3_pkg::Sha3};
      bins shake  = {sha3_pkg::Shake};
      bins cshake = {sha3_pkg::CShake};
    }
    msgfifo_empty:  coverpoint fifo_empty;
    msgfifo_full:   coverpoint fifo_full;
    msgfifo_depth:  coverpoint fifo_depth {
      bins depth[] = {[0 : KMAC_FIFO_DEPTH]};
      bins invalid = default;
    }
  endgroup

  covergroup sha3_status_cg with function sample(bit sha3_idle, bit sha3_absorb, bit sha3_squeeze);
    idle:     coverpoint sha3_idle;
    absorb:   coverpoint sha3_absorb;
    squeeze:  coverpoint sha3_squeeze;
  endgroup

  covergroup state_read_mask_cg with function sample(bit [3:0] mask, bit share_num);
    share: coverpoint share_num;
    `MASK_CP(state_read_mask, mask)
    state_mask_share_cross: cross share, state_read_mask;
  endgroup

  covergroup sideload_cg with function sample(bit en_sideload, bit in_kmac, bit app_keymgr);
    sideload:       coverpoint en_sideload;
    kmac_mode:      coverpoint in_kmac;
    in_app_keymgr:  coverpoint app_keymgr;

    sideload_cross: cross sideload, kmac_mode, in_app_keymgr {
      bins sw_kmac_valid_sideload   = binsof(sideload) intersect {1} && binsof(kmac_mode);
      bins sw_kmac_invalid_sideload = binsof(sideload) intersect {0} && binsof(kmac_mode);
      bins app_valid_sideload       = binsof(sideload) intersect {1} && binsof(in_app_keymgr);
      bins app_invalid_sideload     = binsof(sideload) intersect {0} && binsof(in_app_keymgr);
    }
  endgroup

  covergroup error_cg with function sample(kmac_pkg::err_code_e kmac_err,
                                           kmac_pkg::kmac_cmd_e kcmd,
                                           sha3_pkg::sha3_mode_e kmode,
                                           sha3_pkg::keccak_strength_e kstrength);
    kmac_err_code: coverpoint kmac_err {
      ignore_bins ignore = {kmac_pkg::ErrNone};
      // Covered by direct sequence, if scb enabled for those seq, can remove it from this list.
      illegal_bins il = {kmac_pkg::ErrWaitTimerExpired,
                         kmac_pkg::ErrIncorrectEntropyMode,
                         kmac_pkg::ErrSwHashingWithoutEntropyReady};
    }

    cmd: coverpoint kcmd {
      ignore_bins ignore = {kmac_pkg::CmdNone};
    }

    mode: coverpoint kmode;

    strength: coverpoint kstrength;

    all_invalid_cmd_in_app_active: cross kmac_err_code, cmd {
      bins invalid_cmds = binsof(kmac_err_code) intersect {kmac_pkg::ErrSwIssuedCmdInAppActive} &&
                          binsof(cmd);

      ignore_bins ignore = !binsof(kmac_err_code) intersect {kmac_pkg::ErrSwIssuedCmdInAppActive};
    }

    all_invalid_mode_strength_cfgs: cross kmac_err_code, mode, strength {
      bins sha3_128_cfgs = binsof(kmac_err_code) intersect {kmac_pkg::ErrUnexpectedModeStrength} &&
                           binsof(mode) intersect {sha3_pkg::Sha3} &&
                           binsof(strength) intersect {sha3_pkg::L128};

      bins shake_224_invalid_cfg =
          binsof(kmac_err_code) intersect {kmac_pkg::ErrUnexpectedModeStrength} &&
          binsof(mode) intersect {sha3_pkg::Shake} &&
          binsof(strength) intersect {sha3_pkg::L224};

      bins shake_384_invalid_cfg =
          binsof(kmac_err_code) intersect {kmac_pkg::ErrUnexpectedModeStrength} &&
          binsof(mode) intersect {sha3_pkg::Shake} &&
          binsof(strength) intersect {sha3_pkg::L384};

      bins shake_512_invalid_cfg =
          binsof(kmac_err_code) intersect {kmac_pkg::ErrUnexpectedModeStrength} &&
          binsof(mode) intersect {sha3_pkg::Shake} &&
          binsof(strength) intersect {sha3_pkg::L512};

      bins cshake_224_invalid_cfg =
          binsof(kmac_err_code) intersect {kmac_pkg::ErrUnexpectedModeStrength} &&
          binsof(mode) intersect {sha3_pkg::CShake} &&
          binsof(strength) intersect {sha3_pkg::L224};

      bins cshake_384_invalid_cfg =
          binsof(kmac_err_code) intersect {kmac_pkg::ErrUnexpectedModeStrength} &&
          binsof(mode) intersect {sha3_pkg::CShake} &&
          binsof(strength) intersect {sha3_pkg::L384};

      bins cshake_512_invalid_cfg =
          binsof(kmac_err_code) intersect {kmac_pkg::ErrUnexpectedModeStrength} &&
          binsof(mode) intersect {sha3_pkg::CShake} &&
          binsof(strength) intersect {sha3_pkg::L512};

      ignore_bins ignore = !binsof(kmac_err_code) intersect {kmac_pkg::ErrUnexpectedModeStrength} ||
                           ((binsof(mode) intersect {sha3_pkg::Sha3} &&
                             !binsof(strength) intersect {sha3_pkg::L128}) ||
                            (binsof(mode) intersect {sha3_pkg::Shake, sha3_pkg::CShake} &&
                             binsof(strength) intersect {sha3_pkg::L128, sha3_pkg::L256}));
   }
  endgroup

  function void sample_cfg(bit kmac,
                           bit xof,
                           sha3_pkg::keccak_strength_e kstrength,
                           sha3_pkg::sha3_mode_e kmode,
                           kmac_pkg::key_len_e key_len,
                           bit msg_endianness,
                           bit state_endianness,
                           kmac_pkg::entropy_mode_e entropy_mode,
                           bit fast_entropy);

    if (cfg.enable_masking) begin
      config_masked_cg.sample(kmac, xof, kstrength, kmode, key_len, msg_endianness,
                              state_endianness, entropy_mode,
                              fast_entropy);
    end else begin
      config_unmasked_cg.sample(kmac, xof, kstrength, kmode, key_len,
                                msg_endianness, state_endianness);
    end
  endfunction

  covergroup entropy_timer_cg with function sample (bit [9:0]  prescaler,
                                                    bit [15:0] wait_timer,
                                                    bit        entropy_edn_mode);
    prescaler_val: coverpoint prescaler {
      bins zero_val   = {0};
      bins lower_val  = {[1             : {9{1'b1}} / 2 - 1]};
      bins higher_val = {[{9{1'b1}} / 2 : {9{1'b1}}]};
    }
    wait_timer_val: coverpoint wait_timer {
      bins zero_val   = {0};
      bins lower_val  = {[1              : {16{1'b1}} / 2 -1]};
      bins higher_val = {[{16{1'b1}} / 2 : {16{1'b1}}]};
    }
    entropy_edn_mode_enabled: coverpoint entropy_edn_mode;
    entropy_timer_cross: cross prescaler_val, wait_timer_val, entropy_edn_mode_enabled;
  endgroup

  function new(string name, uvm_component parent);
    kmac_app_e app_name = app_name.first;
    super.new(name, parent);
    // [instantiate covergroups here]
    msg_len_cg = new();
    output_digest_len_cg = new();
    prefix_range_cg = new();
    msgfifo_level_cg = new();
    sha3_status_cg = new();
    state_read_mask_cg = new();
    sideload_cg = new();
    error_cg = new();
    entropy_timer_cg = new();
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // [or instantiate covergroups here]
    // Please instantiate sticky_intr_cov array of objects for all interrupts that are sticky
    // See cip_base_env_cov for details
    if (cfg.enable_masking) begin
      config_masked_cg = new();
    end else begin
      config_unmasked_cg = new();
    end
  endfunction

endclass

`undef MASK_CP
`undef SHA3_CROSS_CG
`undef XOF_CROSS_CG
`undef COMMON_CFG_CGS
