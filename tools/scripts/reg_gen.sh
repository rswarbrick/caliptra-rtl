#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/keyvault/data/kv_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/keyvault/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/keyvault/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/pcrvault/data/pv_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/pcrvault/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/pcrvault/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/datavault/data/dv_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/datavault/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/datavault/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/ecc/data/ecc_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/ecc/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/ecc/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/sha512/data/sha512_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/sha512/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/sha512/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/sha256/data/sha256_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/sha256/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/sha256/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/sha3/data/sha3_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/sha3/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/sha3/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/soc_ifc/data/mbox_csr.rdl \
    --rtl-output $CALIPTRA_ROOT/src/soc_ifc/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/soc_ifc/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/soc_ifc/data/sha512_acc_csr.rdl \
    --rtl-output $CALIPTRA_ROOT/src/soc_ifc/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/soc_ifc/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/soc_ifc/data/soc_ifc_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/soc_ifc/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/soc_ifc/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/hmac/data/hmac_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/hmac/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/hmac/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/doe/data/doe_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/doe/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/doe/dv/reg_model

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/axi/data/axi_dma_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/axi/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/axi/dv/reg_model

# AES wrapper regblock RTL only — its UVM RAL is emitted by the composite
# aes_dv_reg.rdl below, which exposes both wrapper CSRs and the OT AES core
# under a single addrmap at the offsets the VH adapter routes them to.
python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/aes/data/aes_clp_reg.rdl \
    --rtl-output $CALIPTRA_ROOT/src/aes/rtl/generated \
    --rtl-only

# Block-level DV composite RAL (UVM + coverage scaffolding) — UVM-only; the
# regblock RTL for each sub-block is generated separately above and from the
# OT AES core's own source tree.
python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/aes/data/aes_dv_reg.rdl \
    --dv-output  $CALIPTRA_ROOT/src/aes/dv/reg_model \
    --dv-only \
    --cov

python3 tools/scripts/reg_gen.py $CALIPTRA_ROOT/src/libs/data/interrupt_regs.rdl \
    --rtl-output $CALIPTRA_ROOT/src/libs/rtl/generated \
    --dv-output  $CALIPTRA_ROOT/src/libs/dv/reg_model
