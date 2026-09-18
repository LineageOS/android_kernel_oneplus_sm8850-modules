load(":repo_paths.bzl", "modules_label", "soc_label")
load("//build/kernel/kleaf:kernel.bzl", "ddk_module")
load("//build/bazel_common_rules/dist:dist.bzl", "copy_to_dist_dir")
load("//vendor/qcom/sm8850-modules/qcom/opensource/mm-drivers:target_variants.bzl", "get_all_variants")

def _define_module(target, variant):
    tv = "{}_{}".format(target, variant)

    deps = [
        soc_label("all_headers"),
        soc_label("{}/drivers/remoteproc/rproc_qcom_common".format(tv)),
        soc_label("{}/drivers/remoteproc/qcom_q6v5_pas".format(tv)),
        soc_label("{}/drivers/virt/gunyah/gh_dbl".format(tv)),
        soc_label("{}/drivers/virt/gunyah/gh_rm_drv".format(tv)),
        soc_label("{}/drivers/firmware/qcom/qcom-scm".format(tv)),
        soc_label("{}/drivers/soc/qcom/hab/msm_hab".format(tv)),
    ]
    kernel_build = soc_label("{}_base_kernel".format(tv))

    if target in ["pineapple"]:
        target_config = "defconfig"
    else:
        target_config = "{}_defconfig".format(target)

    ddk_module(
        name = "{}_msm_hw_fence".format(tv),
        srcs = [
            "src/hw_fence_drv_debug.c",
            "src/hw_fence_drv_ipc.c",
            "src/hw_fence_drv_priv.c",
            "src/hw_fence_drv_utils.c",
            "src/msm_hw_fence.c",
        ],
        out = "msm_hw_fence.ko",
        defconfig = target_config,
        kconfig = "Kconfig",
        conditional_srcs = {
            "CONFIG_DEBUG_FS": {
                True: ["src/hw_fence_ioctl.c"],
            },
            "CONFIG_QTI_HW_FENCE_USE_SYNX": {
                True: [
                    "src/msm_hw_fence_synx_translation.c",
                    "src/hw_fence_drv_interop.c",
                ],
            },
            "CONFIG_MSM_HAB" : {
                True: ["src/hw_fence_drv_virtio.c"],
            }
        },
        deps = deps + [
            modules_label("qcom/opensource/synx-kernel:synx_headers"),
            modules_label("qcom/opensource/mm-drivers:mm_drivers_headers"),
        ],
        kernel_build = kernel_build,
    )

    copy_to_dist_dir(
        name = "{}_msm_hw_fence_dist".format(tv),
        data = [":{}_msm_hw_fence".format(tv)],
        dist_dir = "out/target/product/{}/dlkm/lib/modules".format(target),
        flat = True,
        wipe_dist_dir = False,
        allow_duplicate_filenames = False,
        mode_overrides = {"**/*": "644"},
        log = "info",
    )

def define_hw_fence():
    for (t, v) in get_all_variants():
        if t == "malabar":
            continue
        _define_module(t, v)
