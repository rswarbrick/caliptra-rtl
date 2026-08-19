// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// A package with types needed by the coverage core (which contains this package) and the
// environment (which depends on the coverage core).

package entropy_src_cov_pkg;

  typedef enum int {
    sfifo_esrng   = 0,
    sfifo_distr   = 1,
    sfifo_observe = 2,
    sfifo_esfinal = 3
  } which_fifo_e;

  typedef enum int {
    write = 0,
    read  = 1,
    state = 2
  } which_fifo_err_e;

  typedef enum int {
    invalid_fips_enable             = 0,
    invalid_entropy_data_reg_enable = 1,
    invalid_module_enable           = 2,
    invalid_threshold_scope         = 3,
    invalid_rng_bit_enable          = 4,
    invalid_fw_ov_mode              = 5,
    invalid_fw_ov_entropy_insert    = 6,
    invalid_fw_ov_insert_start      = 7,
    invalid_es_route                = 8,
    invalid_es_type                 = 9,
    invalid_alert_threshold         = 10,
    invalid_fips_flag               = 11,
    invalid_rng_fips                = 12
  } invalid_mubi_e;

  typedef enum int {
    repcnt_ht  = 0,
    repcnts_ht = 1,
    adaptp_ht  = 2,
    bucket_ht  = 3,
    markov_ht  = 4
  } health_test_e;

  typedef enum int {
    high_test = 0,
    low_test  = 1
  } which_ht_e;

  typedef enum int {
    window_cntr     = 0,
    repcnt_ht_cntr  = 1,
    repcnts_ht_cntr = 2,
    adaptp_ht_cntr  = 3,
    bucket_ht_cntr  = 4,
    markov_ht_cntr  = 5
  } cntr_e;

endpackage
