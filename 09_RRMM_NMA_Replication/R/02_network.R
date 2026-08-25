# ===========================================================================
# 02_network.R  ·  画 RRMM 的证据网络图
#
# 运行方式(从 case 根目录):  Rscript R/02_network.R
#
# 这个脚本分五节。奇数节我写好了,可以直接跑;
# 偶数节里有 TODO —— 那是留给你的。先跑一遍看它在哪里断,再往里填。
# ===========================================================================

root <- "."
stopifnot(dir.exists(file.path(root, "data")))
library(igraph)

# ---------------------------------------------------------------------------
# §1 读数据                                                        【已写好】
# ---------------------------------------------------------------------------
# rrmm_binomial_cr.csv 每行一个臂:trial / arm(1或2) / tx(简称) / tx_index / r / n
#   r = 达到完全缓解(CR)的人数
#   n = ITT 人数
arms <- read.csv(file.path(root, "data", "rrmm_binomial_cr.csv"),
                 stringsAsFactors = FALSE)

cat(sprintf("读入 %d 臂 · %d 个试验 · %d 个治疗节点\n\n",
            nrow(arms), length(unique(arms$trial)), length(unique(arms$tx_index))))

# 先看一眼数据长什么样
print(head(arms, 4))
cat("\n")


# ---------------------------------------------------------------------------
# §2 把「每行一个臂」变成「每行一个试验」                            【你来填】
# ---------------------------------------------------------------------------
# 网络图的一条边 = 一个试验比较了哪两个治疗。
# 所以要把 arms 的两行(arm 1 和 arm 2)并成一行。
#
# 目标:得到一个 data.frame,每行一个试验,至少有这几列
#   trial / tx1 / tx2 (两端的治疗简称) / r1 / n1 / r2 / n2
#
# 提示:最直白的写法是把 arms 拆成两半再按 trial 合并 ——
#   a1 <- arms[arms$arm == 1, ]
#   a2 <- arms[arms$arm == 2, ]
#   merge(a1, a2, by = "trial", suffixes = c("1", "2"))
# merge 会自动把同名列加上后缀,所以 tx 会变成 tx1 / tx2,r 变成 r1 / r2。

a1 <- arms[arms$arm == 1, ]
a2 <- arms[arms$arm == 2, ]
edges <- merge(a1, a2, by = "trial", suffixes = c("1", "2"))

stopifnot(!is.null(edges), nrow(edges) == 17)   # 17 个试验 = 17 条边
cat("§2 通过:", nrow(edges), "条边\n\n")


# ---------------------------------------------------------------------------
# §2b 节点名 —— 一个坑,我上一版踩了                                【已写好】
# ---------------------------------------------------------------------------
# tx 那一列是 Table 1 的治疗标签,有 18 个不同的值;但网络只有 16 个节点。
# 差在两处合并:APEX 的 "Bor" 和 ENDEAVOR 的 "BorDex" 是同一个节点,
# Thal 和 ThalDex 也是。所以建图必须用 tx_index,不能用标签文字。
node_name <- c("Dex", "Bor/BorDex", "LenDex", "PomDex", "PomBorDex",
               "CarLenDex", "EloLenDex", "IxaLenDex", "CarDex", "PanoBorDex",
               "Thal/ThalDex", "BorThalDex", "DaraBorDex", "DaraLenDex",
               "OblDex", "PLDBor")
edges$node1 <- node_name[edges$tx_index1]
edges$node2 <- node_name[edges$tx_index2]

cat("§2b 标签", length(unique(c(edges$tx1, edges$tx2))), "个 → 节点",
    length(unique(c(edges$node1, edges$node2))), "个\n\n")


# ---------------------------------------------------------------------------
# §3 一条边对 CRR 有没有信息                                       【已写好】
# ---------------------------------------------------------------------------
# 两个臂都是 0 个 CR(或都是全员 CR)时,这条边对「谁的 CR 率更高」
# 说不出任何话 —— 似然在那个方向上不收敛,后验≈先验。
# 注意:这是**二分类**模型下的判断。多项式模型里这条边并没有死,
# 因为它还能从 PR / <PR 的分布里借到信息。这一点我们后面会对比。
informative <- function(r1, n1, r2, n2) {
  !((r1 == 0 && r2 == 0) || (r1 == n1 && r2 == n2))
}
edges$live <- mapply(informative, edges$r1, edges$n1, edges$r2, edges$n2)

cat("§3 对 CRR 有信息的边:", sum(edges$live), "/", nrow(edges), "\n")
cat("   死边:", paste(edges$trial[!edges$live], collapse = ", "), "\n\n")


# ---------------------------------------------------------------------------
# §4 画图                                                          【你来填】
# ---------------------------------------------------------------------------
# igraph 的用法:先用两列(起点、终点)建图,再画。
#   g <- graph_from_data_frame(edges[, c("node1", "node2")], directed = FALSE)
#
# 我们要的三件事:
#   (a) 死边画成虚线,活边画成实线
#   (b) 边的粗细 = 该比较有几个试验(LenDex vs Dex 有两个:MM-009 和 MM-010)
#   (c) 参照治疗 Dex 用不同颜色标出来
#
# 提示:igraph 的 plot() 接受这些参数 ——
#   edge.lty   = 每条边的线型,1 是实线 2 是虚线。用 ifelse(edges$live, 1, 2)
#   edge.width = 每条边的粗细,给一个数值向量
#   vertex.color = 每个节点的颜色。节点顺序用 V(g)$name 查
#
# (b) 稍微绕一点:同一对治疗可能出现在多个试验里,要先数出来。
#     想不出来就先跳过 (b),把 (a)(c) 做出来图就已经能看了。

# (a)(c) 我写好了,(b) 在下面留给你。
# 注意用 node1/node2,不是 tx1/tx2 —— 理由见 §2b。
g <- graph_from_data_frame(edges[, c("node1", "node2")], directed = FALSE)

# (a) 死边虚线。ifelse 是向量化的三元判断:条件真取第二个,假取第三个。
#     边的顺序 = edges 的行顺序,所以这些向量能直接对上。
edge_lty <- ifelse(edges$live, 1, 2)
edge_col <- ifelse(edges$live, "grey35", "grey70")

# (c) 参照治疗单独上色。V(g)$name 是 igraph 自己排的节点顺序,
#     和 edges 的行顺序无关,所以要按名字判断,不能按位置。
vertex_col <- ifelse(V(g)$name == "Dex", "#c2410c", "#cbd5e1")
vertex_fg  <- ifelse(V(g)$name == "Dex", "#c2410c", "#94a3b8")

# ---- TODO (b) ----------------------------------------------------------
# 边的粗细 = 该比较有几个试验。现在每条边一样粗;
# LenDex-Dex 有两个试验(MM-009、MM-010),应该更粗。
#
# 思路:先给每条边算一个「比较」的身份,再数每个身份出现几次。
# 陷阱:身份不能直接写 paste(node1, node2) —— 同一个比较在不同试验里
#       两端顺序可能相反,会被当成两个不同的比较。
# 提示:pmin(a, b) / pmax(a, b) 对两个向量逐行取小/取大,能把顺序统一掉。
#       数个数用 table(),取回来用 [ ] 按名字索引。
lo <- pmin(edges$node1, edges$node2)
hi <- pmax(edges$node1, edges$node2)
key <- paste(lo, hi)
counts <- table(key)
n_trials <- counts[key]
edge_w <- 1.5 * as.integer(n_trials)
# ------------------------------------------------------------------------

dir.create(file.path(root, "visuals"), showWarnings = FALSE)
png(file.path(root, "visuals", "network_crr.png"),
    width = 1600, height = 1200, res = 160)
par(mar = c(0, 0, 2, 0))
set.seed(1)                      # 布局有随机性,固定种子每次才画得一样
plot(g,
     layout             = layout_with_fr(g),
     edge.lty           = edge_lty,
     edge.color         = edge_col,
     edge.width         = edge_w,
     vertex.color       = vertex_col,
     vertex.frame.color = vertex_fg,
     vertex.size        = 8,
     vertex.label.color = "black",
     vertex.label.cex   = 0.8,
     vertex.label.dist  = 1.6,
     main = "RRMM evidence network - dashed = no information on CRR")
dev.off()

cat("§4 图已存到 visuals/network_crr.png\n\n")


# ---------------------------------------------------------------------------
# §5 数一数网络的形状                                              【已写好】
# ---------------------------------------------------------------------------
# 这一节把你在图上看到的东西变成数字,写页面时要用。
shape <- function(e, label) {
  gg <- graph_from_data_frame(e[, c("node1", "node2")], directed = FALSE)
  gg <- simplify(gg)                       # 同一对治疗的多个试验算一条比较
  n_node <- gorder(gg); n_edge <- gsize(gg)
  reach <- length(subcomponent(gg, "Dex", mode = "all"))
  cat(sprintf("%-28s 节点 %2d · 不同比较 %2d · 独立回路 %d · 能连到 Dex 的节点 %2d\n",
              label, n_node, n_edge, n_edge - n_node + 1, reach))
}
shape(edges,              "全部 17 个试验")
shape(edges[edges$live, ], "只算对 CRR 有信息的边")
