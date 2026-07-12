# FORCE 论文复现流程说明

本文档用于配合代码复现 Sussillo and Abbott (2009) 的主要结果之一：Figure 2D，即一个原本处于混沌状态的递归神经网络，在 FORCE learning 训练后自主生成由四个正弦波相加得到的周期信号。

## 1. 先定复现目标

第一次做论文复现时，不建议一开始复现整篇论文。本文主文第 3 页的 Figure 2 给出多个任务，其中 Figure 2D 是周期函数，由四个正弦波组成；补充 MATLAB 代码 `force_external_feedback_loop.m` 也直接实现了这个例子。因此本项目先复现：

- 架构：主文 Figure 1A，外部读出反馈到递归网络。
- 结果：主文 Figure 2D，网络输出 `z(t)` 在训练后匹配目标函数 `f(t)`。
- 算法：主文第 4-6 页描述的 FORCE/RLS 学习；参考代码为 `force_external_feedback_loop.m`。

完成这个目标后，再运行 `run_internal_all2all.m`，对应主文 Figure 1C 的 internal learning 简化示例，参考代码为 `force_internal_all2all.m`。

## 2. 建立模型

网络内部状态记为 `x(t)`，发放率记为：

```text
r(t) = tanh(x(t))
```

读出单元定义为：

```text
z(t) = w' r(t)
```

在 Figure 1A 外部反馈架构中，`z(t)` 再通过固定随机反馈权重 `wf` 输入回递归网络。代码中的离散化动力学为：

```text
x(t + dt) = (1 - dt) x(t) + dt M r(t) + dt wf z(t)
```

其中：

- `M` 是固定随机递归连接矩阵。
- `w` 是可学习的读出权重。
- `wf` 是固定随机反馈权重。
- `g > 1` 使随机网络在训练前倾向于混沌活动，这是论文强调 FORCE learning 能处理的难点。

本项目代码位置：

- `code/make_config.m`：集中管理 `N, p, g, alpha, dt, nsecs, learn_every, seed`。
- `code/run_force_external.m`：实现 Figure 1A 外部反馈训练和测试。

## 3. 生成 Figure 2D 目标函数

目标函数来自补充 MATLAB 脚本，写在 `code/make_four_sine_target.m`：

```text
f(t) = [a sin(pi q t) + a/2 sin(2 pi q t)
      + a/6 sin(3 pi q t) + a/3 sin(4 pi q t)] / 1.5
```

默认 `a=1.3`，`q=1/60`。这与 `force_external_feedback_loop.m` 中的 `amp` 和 `freq` 设置一致。

调试时先不要改目标函数。先固定目标和随机种子，确认代码能稳定运行，再改 `N/g/alpha/nsecs`。

## 4. FORCE/RLS 更新怎么做

每隔 `learn_every` 个时间步更新一次读出权重。当前误差为：

```text
e(t) = z(t) - f(t)
```

RLS 使用逆相关矩阵 `P` 来决定每个方向上的学习步长：

```text
k = P r
c = 1 / (1 + r' k)
P <- P - k k' c
dw <- -e k c
w <- w + dw
```

这些公式封装在 `code/rls_update.m`。这样做的好处是：

- 代码和数学公式一一对应，便于检查。
- 测试可以单独验证 `P` 的维度和对称性。
- 报告中可以直接引用这个函数解释算法。

## 5. 训练、测试和判断成功

训练阶段：

1. 初始化随机递归网络。
2. 用当前网络状态计算 `z(t)`。
3. 用 `e(t)=z(t)-f(t)` 更新 `w`。
4. 记录训练输出、目标函数和 `||w||`。

测试阶段：

1. 停止权重更新。
2. 从训练结束的网络状态继续运行。
3. 记录自主输出 `z(t)`。
4. 与后续时间段的目标函数 `f(t)` 比较。

判断标准：

- smoke run：只要求代码稳定、输出有限、能生成 `.mat` 和图。
- full reproduction：测试曲线应明显跟随四正弦目标，testing MAE 应远小于目标幅值。
- 如果结果不好，先检查 `seed`、`g`、`alpha`、训练时长 `nsecs`，不要同时改多个参数。

## 6. 推荐运行顺序

从项目根目录依次运行：

```text
matlab -batch "run('tests/run_all_tests.m')"
matlab -batch "run('scripts/run_smoke.m')"
matlab -batch "run('scripts/run_sweep.m')"
matlab -batch "run('scripts/run_internal_all2all.m')"
matlab -batch "run('scripts/run_reproduction.m')"
```


## 7. 调参记录方法

调参不要凭感觉乱试。建议按以下顺序：

1. 固定 `seed`，保证每次只比较一个因素。
2. 先跑 `smoke`，确认代码正确。
3. 改 `g`：比较 `0.8, 1.2, 1.5, 1.8`。论文中强调 `g > 1` 的混沌网络通常更利于 FORCE 学习。
4. 改 `alpha`：比较 `0.5, 1.0, 2.0`。`alpha` 越大，初始 `P=I/alpha` 越小，更新越保守。
5. 改 `N` 和 `nsecs`：更大的网络和更长训练通常更接近论文结果，但计算更慢。

`scripts/run_sweep.m` 会保存 `results/data/sweep_summary.csv`，报告中的调参表可以从这里整理。

## 8. 文件和引用位置

- 主文 PDF 第 3 页：Figure 2D 和 Figure 2 图注。
- 主文 PDF 第 4-6 页：读出模型、反馈结构和 RLS/FORCE 学习说明。
- 主文 PDF 第 10 页：Figure 1C internal learning 说明。
- 补充 PDF 第 5-6 页：有效连接矩阵和四正弦目标的补充分析。
- 参考 MATLAB：`ScienceDirect_files_22Apr2026_15-15-07.313/1-s2.0-S0896627309005479-mmc2/force_simple_examples/`。
