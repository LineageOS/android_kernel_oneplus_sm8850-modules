load(":repo_paths.bzl", "modules_label", "soc_label")
load("//build/kernel/kleaf:kernel.bzl", "ddk_module")
load("//build/bazel_common_rules/dist:dist.bzl", "copy_to_dist_dir")
load("//vendor/qcom/sm8850-modules/qcom/opensource/mm-drivers:target_variants.bzl", "get_all_variants")

def _define_module(target, variant):
    tv = "{}_{}".format(target, variant)

    deps = select({
        "//build/kernel/kleaf:socrepo_true": [soc_label("all_headers")],
        "//build/kernel/kleaf:socrepo_false": ["//msm-kernel:all_headers"],
    })
    kernel_build = select({
        "//build/kernel/kleaf:socrepo_true": soc_label("{}_base_kernel".format(tv)),
        "//build/kernel/kleaf:socrepo_false": "//msm-kernel:{}".format(tv),
    })

    ddk_module(
        name = "{}_sync_fence".format(tv),
        srcs = ["src/qcom_sync_file.c"],
        out = "sync_fence.ko",
        kconfig = "Kconfig",
        defconfig = "defconfig",
        deps = deps + [
            modules_label("qcom/opensource/mm-drivers:mm_drivers_headers"),
        ],
        kernel_build = kernel_build,
    )

    copy_to_dist_dir(
        name = "{}_sync_fence_dist".format(tv),
        data = [":{}_sync_fence".format(tv)],
        dist_dir = "out/target/product/{}/dlkm/lib/modules".format(target),
        flat = True,
        wipe_dist_dir = False,
        allow_duplicate_filenames = False,
        mode_overrides = {"**/*": "644"},
        log = "info",
    )

def define_sync_fence():
    for (t, v) in get_all_variants():
        _define_module(t, v)
