# MelodyShare — Database Schema

## 运行顺序

所有 `CREATE TABLE IF NOT EXISTS` 可以在一个事务中安全执行。当前 `db.rs` 的 `init_db()` 已自动执行全部建表语句。

## tracks

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `title` | VARCHAR(255) | NOT NULL | 曲目标题 |
| `artist` | VARCHAR(255) | NOT NULL DEFAULT '' | 艺术家 |
| `filename` | VARCHAR(255) | NOT NULL | 原始文件名 |
| `filepath` | VARCHAR(512) | NOT NULL | 服务器上的存储路径 |
| `uploaded_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 上传时间 |

## users

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `username` | VARCHAR(50) | UNIQUE NOT NULL | 登录用户名 |
| `email` | VARCHAR(255) | UNIQUE NOT NULL | 邮箱 |
| `password_hash` | VARCHAR(255) | NOT NULL | bcrypt 加密后的密码 |
| `display_name` | VARCHAR(100) | NOT NULL DEFAULT '' | 展示昵称 |
| `bio` | TEXT | NOT NULL DEFAULT '' | 个人简介 |
| `avatar_url` | VARCHAR(512) | NOT NULL DEFAULT '' | 头像 URL |
| `role` | VARCHAR(20) | NOT NULL DEFAULT 'user' | 角色：`user` / `admin` |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 注册时间 |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 资料更新时间 |

## sessions

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `user_id` | UUID | FK → users(id) ON DELETE CASCADE | 所属用户 |
| `token_hash` | VARCHAR(255) | NOT NULL | 令牌的哈希值 |
| `device_info` | VARCHAR(255) | NOT NULL DEFAULT '' | 设备信息（UA 等） |
| `expires_at` | TIMESTAMPTZ | NOT NULL | 过期时间 |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 创建时间 |

## playlists

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `user_id` | UUID | FK → users(id) ON DELETE CASCADE | 创建者 |
| `title` | VARCHAR(255) | NOT NULL | 歌单名 |
| `description` | TEXT | NOT NULL DEFAULT '' | 描述 |
| `cover_url` | VARCHAR(512) | NOT NULL DEFAULT '' | 封面图 URL |
| `is_public` | BOOLEAN | NOT NULL DEFAULT TRUE | 是否公开 |
| `track_count` | INTEGER | NOT NULL DEFAULT 0 | 曲目数量（冗余计数） |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 创建时间 |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 更新时间 |

## playlist_tracks

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `playlist_id` | UUID | FK → playlists(id) ON DELETE CASCADE | 所属歌单 |
| `track_id` | UUID | FK → tracks(id) ON DELETE CASCADE | 曲目 |
| `sort_order` | INTEGER | NOT NULL DEFAULT 0 | 排序序号 |
| `added_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 添加时间 |

**UNIQUE**(playlist_id, track_id)

## follows

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `follower_id` | UUID | FK → users(id) ON DELETE CASCADE | 关注者 |
| `followee_id` | UUID | FK → users(id) ON DELETE CASCADE | 被关注者 |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 关注时间 |

**UNIQUE**(follower_id, followee_id)

## track_likes

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `user_id` | UUID | FK → users(id) ON DELETE CASCADE | 点赞用户 |
| `track_id` | UUID | FK → tracks(id) ON DELETE CASCADE | 被点赞曲目 |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 点赞时间 |

**UNIQUE**(user_id, track_id)

## comments

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `user_id` | UUID | FK → users(id) ON DELETE CASCADE | 评论者 |
| `track_id` | UUID | FK → tracks(id) ON DELETE CASCADE | 所属曲目 |
| `parent_id` | UUID? | FK → comments(id) ON DELETE CASCADE | 父评论 ID（NULL 为顶级评论） |
| `content` | TEXT | NOT NULL | 正文 |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 评论时间 |
| `updated_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 编辑时间 |

## notifications

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| `id` | UUID | PK | 唯一标识 |
| `user_id` | UUID | FK → users(id) ON DELETE CASCADE | 通知接收者 |
| `actor_id` | UUID? | FK → users(id) ON DELETE SET NULL | 触发者（用户注销后保留通知） |
| `type` | VARCHAR(50) | NOT NULL | 通知类型：`follow` / `like` / `comment` / `reply` / `playlist_add` |
| `entity_type` | VARCHAR(50) | NOT NULL DEFAULT '' | 关联实体类型：`"user"` / `"track"` / `"comment"` / `"playlist"` |
| `entity_id` | UUID? | — | 关联实体 ID |
| `content` | TEXT | NOT NULL DEFAULT '' | 预览文本 |
| `is_read` | BOOLEAN | NOT NULL DEFAULT FALSE | 是否已读 |
| `created_at` | TIMESTAMPTZ | NOT NULL DEFAULT NOW() | 通知时间 |

## 索引汇总

| 索引 | 表 | 列 | 用途 |
|---|---|---|---|
| `idx_sessions_user_id` | sessions | `user_id` | 查询用户会话 |
| `idx_sessions_expires_at` | sessions | `expires_at` | 清理过期会话 |
| `idx_playlists_user_id` | playlists | `user_id` | 查询用户歌单 |
| `idx_playlist_tracks_playlist` | playlist_tracks | `playlist_id` | 查询歌单内容 |
| `idx_playlist_tracks_track` | playlist_tracks | `track_id` | 反查曲目所在歌单 |
| `idx_playlist_tracks_sort` | playlist_tracks | `playlist_id, sort_order` | 按序取歌 |
| `idx_follows_follower` | follows | `follower_id` | 查询关注列表 |
| `idx_follows_followee` | follows | `followee_id` | 查询粉丝列表 |
| `idx_track_likes_user` | track_likes | `user_id` | 查询用户喜欢列表 |
| `idx_track_likes_track` | track_likes | `track_id` | 查询曲目被赞数 |
| `idx_comments_track` | comments | `track_id` | 查询曲目评论 |
| `idx_comments_parent` | comments | `parent_id` | 查询回复列表 |
| `idx_notifications_user` | notifications | `user_id` | 查询用户通知 |
| `idx_notifications_unread` | notifications | `user_id, is_read` | 未读通知查询 |

## migration 文件规范

文件名格式：`<序号>_<描述>.sql`

- `001_community_schema.sql` — 初始社区全套表结构
- 后续变更以递增序号追加，保持幂等（`IF NOT EXISTS` / `IF EXISTS`）。
