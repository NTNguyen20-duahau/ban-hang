-- WEB QUẢN LÝ CỬA HÀNG — Nông Nghiệp Tây Nguyên / TKA Hòa Nam
-- Cơ sở dữ liệu trên Supabase (PostgreSQL). Chạy toàn bộ file này 1 lần trong SQL Editor.
-- Dữ liệu nằm trong schema "bh" (không mở ra ngoài). Trang web chỉ gọi được hàm public.api(tk, viec, d).

create schema if not exists bh;
revoke all on schema bh from public;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'anon') then execute 'revoke all on schema bh from anon, authenticated'; end if;
end $$;

create table if not exists bh.cai_dat (muc text primary key, gia_tri text not null default '');
create table if not exists bh.nhan_vien (
  id serial primary key, ten_dang_nhap text not null unique, ho_ten text not null default '',
  salt text not null, hash text not null, la_chu boolean not null default false,
  quyen text[] not null default '{}', bi_khoa boolean not null default false);
create table if not exists bh.phien (tk text primary key, nv_id int not null, salt text not null, het bigint not null);
create table if not exists bh.sai_dn (ten text primary key, so int not null, het bigint not null);
create table if not exists bh.hang_hoa (
  id serial primary key, ten text not null, don_vi text not null default '', gia_ban bigint not null default 0,
  gia_nhap bigint not null default 0, ton bigint not null default 0, ton_toi_thieu bigint not null default 0, ngung boolean not null default false);
create table if not exists bh.khach_hang (
  id serial primary key, ten text not null, sdt text not null default '', dia_chi text not null default '',
  han_muc bigint not null default 0, no bigint not null default 0, ngung boolean not null default false);
create table if not exists bh.hoa_don (
  id serial primary key, loai text not null, thoi_gian bigint not null, kh_id int not null default 0, kh_ten text not null default '',
  kh_sdt text not null default '', kh_dia_chi text not null default '', tong bigint not null default 0, giam_gia bigint not null default 0,
  no_cu bigint not null default 0, thanh_toan bigint not null default 0, con_no bigint not null default 0, nhan_vien text not null default '',
  trang_thai text not null default 'OK', ghi_chu text not null default '', chi_tiet text not null default '', items jsonb not null default '[]');
create table if not exists bh.thu_no (
  id serial primary key, thoi_gian bigint not null, kh_id int not null, kh_ten text not null default '', no_cu bigint not null default 0,
  so_tien bigint not null default 0, con_no bigint not null default 0, nhan_vien text not null default '',
  trang_thai text not null default 'OK', ghi_chu text not null default '');
create table if not exists bh.doi_tac (
  id serial primary key, ten text not null, sdt text not null default '', dia_chi text not null default '',
  no bigint not null default 0, no_ke_toan bigint, ngung boolean not null default false);
create table if not exists bh.phieu_nhap (
  id serial primary key, thoi_gian bigint not null, tong bigint not null default 0, nhan_vien text not null default '',
  trang_thai text not null default 'OK', ghi_chu text not null default '', chi_tiet text not null default '', items jsonb not null default '[]',
  dt_id int not null default 1, dt_ten text not null default 'TKA');
create table if not exists bh.tra_doi_tac (
  id serial primary key, thoi_gian bigint not null, so_tien bigint not null default 0, nhan_vien text not null default '',
  trang_thai text not null default 'OK', ghi_chu text not null default '', dt_id int not null default 1, dt_ten text not null default 'TKA');
create table if not exists bh.kiem_kho (
  id bigserial primary key, thoi_gian bigint not null, hh_id int not null, ten text not null default '',
  ton_so bigint not null default 0, ton_thuc bigint not null default 0, chenh_lech bigint not null default 0, nhan_vien text not null default '');
create table if not exists bh.nhat_ky (id bigserial primary key, thoi_gian bigint not null, nhan_vien text not null default '', hanh_dong text not null default '', chi_tiet text not null default '');
create table if not exists bh.ma_da_lam (ma text primary key, kq jsonb not null, luc bigint not null);
-- số liệu từ phần mềm cũ (trước khi dùng web), theo tháng
create table if not exists bh.slc_hang (
  id bigserial primary key, thang text not null, tu bigint not null, den bigint not null, hh_id int not null default 0,
  ten_goc text not null default '', sl numeric not null default 0, von bigint not null default 0, doanh_thu bigint not null default 0);
create index if not exists slc_hang_thang on bh.slc_hang (thang);

alter table bh.hoa_don add column if not exists khong_tinh_bc boolean not null default false;
create index if not exists hoa_don_kh on bh.hoa_don (kh_id);
create index if not exists hoa_don_tg on bh.hoa_don (thoi_gian);
create index if not exists thu_no_kh on bh.thu_no (kh_id);
create index if not exists thu_no_tg on bh.thu_no (thoi_gian);
create index if not exists phieu_nhap_dt on bh.phieu_nhap (dt_id);
create index if not exists phieu_nhap_tg on bh.phieu_nhap (thoi_gian);
create index if not exists tra_dt on bh.tra_doi_tac (dt_id);
create index if not exists nhat_ky_tg on bh.nhat_ky (thoi_gian);

do $$ declare t text; begin
  foreach t in array array['cai_dat','nhan_vien','phien','sai_dn','hang_hoa','khach_hang','hoa_don','thu_no','doi_tac','phieu_nhap','tra_doi_tac','kiem_kho','nhat_ky','ma_da_lam','slc_hang'] loop
    execute format('alter table bh.%I enable row level security', t);
  end loop;
end $$;

insert into bh.cai_dat (muc, gia_tri) values
  ('ten1','Nông Nghiệp Tây Nguyên'),('ten2','TKA Hòa Nam'),('sdt','0961.414.747'),
  ('diaChi','Thôn 3A, Xã Hòa Bắc, Tỉnh Lâm Đồng'),('loiCamOn',''),('tonToiThieu','5')
on conflict (muc) do nothing;
insert into bh.doi_tac (id, ten) select 1, 'TKA' where not exists (select 1 from bh.doi_tac);
select setval(pg_get_serial_sequence('bh.doi_tac','id'), greatest((select max(id) from bh.doi_tac), 1));

/* ====================== TIỆN ÍCH ====================== */

create or replace function bh.bay_gio() returns bigint language sql volatile as
$$ select (extract(epoch from clock_timestamp()) * 1000)::bigint $$;

create or replace function bh.loi(m text) returns void language plpgsql as
$$ begin raise exception using errcode = 'BH001', message = m; end $$;

-- giống Math.round(Number(x)) của JavaScript, không hợp lệ -> 0
create or replace function bh.so(x jsonb) returns bigint language plpgsql immutable as $$
declare s text;
begin
  if x is null then return 0; end if;
  case jsonb_typeof(x)
    when 'number' then return floor((x #>> '{}')::numeric + 0.5)::bigint;
    when 'boolean' then return case when (x #>> '{}')::boolean then 1 else 0 end;
    when 'string' then
      s := btrim(x #>> '{}');
      if s = '' then return 0; end if;
      if s ~ '^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$' then return floor(s::numeric + 0.5)::bigint; end if;
      return 0;
    else return 0;
  end case;
exception when others then return 0;
end $$;

create or replace function bh.chu(x text) returns text language sql immutable as
$$ select regexp_replace(btrim(regexp_replace(coalesce(x, ''), '\s+', ' ', 'g')), '^=+', '') $$;

-- giá trị "đúng" theo kiểu JavaScript
create or replace function bh.dung(x jsonb) returns boolean language sql immutable as $$
  select case when x is null then false
    when jsonb_typeof(x) = 'null' then false
    when jsonb_typeof(x) = 'boolean' then (x #>> '{}')::boolean
    when jsonb_typeof(x) = 'number' then (x #>> '{}')::numeric <> 0
    when jsonb_typeof(x) = 'string' then (x #>> '{}') <> ''
    else true end $$;

-- có giá trị (khác null / không thiếu) — giống "x != null"
create or replace function bh.co_gt(x jsonb) returns boolean language sql immutable as
$$ select x is not null and jsonb_typeof(x) <> 'null' $$;

create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- cách cũ (SHA-256), chỉ còn dùng để kiểm tra mật khẩu tạo từ bản Google
create or replace function bh.bam(salt text, mk text) returns text language sql immutable as
$$ select encode(sha256(convert_to(salt || '|' || mk, 'UTF8')), 'hex') $$;

-- mật khẩu mới: bcrypt (mã hoá chậm, khó dò)
create or replace function bh.tao_hash(mk text) returns text language sql volatile as
$$ select extensions.crypt(mk, extensions.gen_salt('bf', 10)) $$;

create or replace function bh.dung_mk(r bh.nhan_vien, mk text) returns boolean language sql stable as $$
  select case when r.hash like '$2%' then r.hash = extensions.crypt(coalesce(mk, ''), r.hash)
    else r.hash = bh.bam(r.salt, coalesce(mk, '')) end $$;

create or replace function bh.quyen_ds() returns jsonb language sql immutable as $$ select jsonb_build_object(
  'xemGiaNhap','Xem giá nhập, lợi nhuận', 'xemBaoCao','Xem báo cáo doanh thu', 'suaGia','Sửa giá bán',
  'suaHang','Thêm / sửa / ẩn mặt hàng', 'nhapHang','Nhập hàng', 'kiemKho','Kiểm kho (sửa số tồn)',
  'suaHoaDon','Sửa / huỷ hoá đơn, phiếu thu', 'hanMuc','Đặt / sửa hạn mức nợ', 'vuotHanMuc','Cho khách mua vượt hạn mức',
  'congNoTKA','Xem và ghi công nợ đối tác') $$;

create or replace function bh.co(u bh.nhan_vien, q text) returns boolean language sql stable as
$$ select u.la_chu or q = any(u.quyen) $$;

create or replace function bh.can(u bh.nhan_vien, q text) returns void language plpgsql as $$
begin if not bh.co(u, q) then perform bh.loi('Bạn chưa được cấp quyền: ' || (bh.quyen_ds() ->> q)); end if; end $$;

create or replace function bh.chu1(u bh.nhan_vien) returns void language plpgsql as $$
begin if not u.la_chu then perform bh.loi('Chỉ chủ cửa hàng mới làm được việc này.'); end if; end $$;

create or replace function bh.nhat_ky_(u bh.nhan_vien, hanh_dong text, chi_tiet text) returns void language sql as
$$ insert into bh.nhat_ky (thoi_gian, nhan_vien, hanh_dong, chi_tiet) values (bh.bay_gio(), coalesce(u.ho_ten, ''), hanh_dong, coalesce(chi_tiet, '')) $$;

create or replace function bh.trong(t bigint, d jsonb) returns boolean language sql immutable as
$$ select (not bh.dung(d->'tu') or t >= bh.so(d->'tu')) and (not bh.dung(d->'den') or t <= bh.so(d->'den')) $$;

create or replace function bh.cai_dat_() returns jsonb language sql stable as $$
  select jsonb_build_object('ten1', coalesce(max(gia_tri) filter (where muc='ten1'), ''), 'ten2', coalesce(max(gia_tri) filter (where muc='ten2'), ''),
    'sdt', coalesce(max(gia_tri) filter (where muc='sdt'), ''), 'diaChi', coalesce(max(gia_tri) filter (where muc='diaChi'), ''),
    'loiCamOn', coalesce(max(gia_tri) filter (where muc='loiCamOn'), ''),
    'tonToiThieu', bh.so(to_jsonb(coalesce(max(gia_tri) filter (where muc='tonToiThieu'), '0'))))
  from bh.cai_dat $$;

create or replace function bh.dat_cai_dat(k text, v text) returns void language sql as
$$ insert into bh.cai_dat (muc, gia_tri) values (k, v) on conflict (muc) do update set gia_tri = excluded.gia_tri $$;

/* ====================== DỮ LIỆU GỬI RA TRANG WEB ====================== */

create or replace function bh.nv_cong(r bh.nhan_vien) returns jsonb language sql stable as $$
  select jsonb_build_object('id', r.id, 'tenDangNhap', r.ten_dang_nhap, 'hoTen', r.ho_ten, 'laChu', r.la_chu, 'biKhoa', r.bi_khoa,
    'quyen', coalesce((select jsonb_agg(q) from unnest(r.quyen) q where bh.quyen_ds() ? q), '[]'::jsonb)) $$;

create or replace function bh.hh_cong(u bh.nhan_vien, p bh.hang_hoa) returns jsonb language sql stable as $$
  select jsonb_build_object('id', p.id, 'ten', p.ten, 'donVi', p.don_vi, 'giaBan', p.gia_ban, 'ton', p.ton, 'tonToiThieu', p.ton_toi_thieu, 'ngung', p.ngung)
    || case when bh.co(u, 'xemGiaNhap') then jsonb_build_object('giaNhap', p.gia_nhap) else '{}'::jsonb end $$;

create or replace function bh.kh_cong(k bh.khach_hang) returns jsonb language sql stable as $$
  select jsonb_build_object('id', k.id, 'ten', k.ten, 'sdt', k.sdt, 'diaChi', k.dia_chi, 'hanMuc', k.han_muc, 'no', k.no, 'ngung', k.ngung) $$;

create or replace function bh.hd_cong(u bh.nhan_vien, r bh.hoa_don) returns jsonb language sql stable as $$
  select jsonb_build_object('kieu', 'HD', 'id', r.id, 'loai', r.loai, 'thoiGian', r.thoi_gian, 'khId', r.kh_id, 'khTen', r.kh_ten, 'khSdt', r.kh_sdt,
    'khDiaChi', r.kh_dia_chi, 'tong', r.tong, 'giamGia', r.giam_gia, 'noCu', r.no_cu, 'thanhToan', r.thanh_toan, 'conNo', r.con_no,
    'nhanVien', r.nhan_vien, 'trangThai', r.trang_thai, 'ghiChu', r.ghi_chu, 'khongTinhBC', r.khong_tinh_bc,
    'items', case when bh.co(u, 'xemGiaNhap') then r.items
      else coalesce((select jsonb_agg(it - 'von' order by n) from jsonb_array_elements(r.items) with ordinality a(it, n)), '[]'::jsonb) end) $$;

create or replace function bh.thu_cong(r bh.thu_no) returns jsonb language sql stable as $$
  select jsonb_build_object('kieu', 'THU', 'id', r.id, 'thoiGian', r.thoi_gian, 'khId', r.kh_id, 'khTen', r.kh_ten, 'noCu', r.no_cu,
    'soTien', r.so_tien, 'conNo', r.con_no, 'nhanVien', r.nhan_vien, 'trangThai', r.trang_thai, 'ghiChu', r.ghi_chu) $$;

create or replace function bh.nhap_cong(u bh.nhan_vien, r bh.phieu_nhap) returns jsonb language sql stable as $$
  select jsonb_build_object('id', r.id, 'thoiGian', r.thoi_gian, 'nhanVien', r.nhan_vien, 'trangThai', r.trang_thai, 'ghiChu', r.ghi_chu,
    'items', case when bh.co(u, 'xemGiaNhap') then r.items
      else coalesce((select jsonb_agg(it - 'gia' - 'giaCu' order by n) from jsonb_array_elements(r.items) with ordinality a(it, n)), '[]'::jsonb) end,
    'dtId', coalesce(nullif(r.dt_id, 0), 1), 'dtTen', coalesce(nullif(r.dt_ten, ''), 'TKA'))
    || case when bh.co(u, 'xemGiaNhap') then jsonb_build_object('tong', r.tong) else '{}'::jsonb end $$;

create or replace function bh.dt_cong(r bh.doi_tac) returns jsonb language sql stable as $$
  select jsonb_build_object('id', r.id, 'ten', r.ten, 'sdt', r.sdt, 'diaChi', r.dia_chi, 'no', r.no, 'noKeToan', r.no_ke_toan, 'ngung', r.ngung) $$;

/* ====================== ĐĂNG NHẬP ====================== */

create or replace function bh.ten_dn(s text) returns text language plpgsql as $$
begin
  s := lower(bh.chu(s));
  if s !~ '^[a-z0-9._]{2,20}$' then perform bh.loi('Tên đăng nhập chỉ gồm chữ thường không dấu, số, dấu chấm (2–20 ký tự).'); end if;
  return s;
end $$;

create or replace function bh.kt_mk(mk text) returns text language plpgsql as $$
begin
  mk := coalesce(mk, '');
  if length(mk) < 4 then perform bh.loi('Mật khẩu phải có ít nhất 4 ký tự.'); end if;
  return mk;
end $$;

create or replace function bh.tao_phien(r bh.nhan_vien) returns text language plpgsql as $$
declare tk text := replace(gen_random_uuid()::text, '-', '') || replace(gen_random_uuid()::text, '-', '');
begin
  delete from bh.phien where het < bh.bay_gio();
  insert into bh.phien (tk, nv_id, salt, het) values (tk, r.id, r.salt, bh.bay_gio() + 30::bigint * 24 * 3600 * 1000);
  return tk;
end $$;

create or replace function bh.xac_thuc(p_tk text) returns bh.nhan_vien language plpgsql as $$
declare ph bh.phien; r bh.nhan_vien;
begin
  if p_tk is null or p_tk = '' then return null; end if;
  select * into ph from bh.phien where tk = p_tk;
  if not found then return null; end if;
  if ph.het < bh.bay_gio() then delete from bh.phien where tk = p_tk; return null; end if;
  select * into r from bh.nhan_vien where id = ph.nv_id;
  if not found or r.bi_khoa or r.salt <> ph.salt then return null; end if;
  return r;
end $$;

create or replace function bh.tao_chu(d jsonb) returns jsonb language plpgsql as $$
declare r bh.nhan_vien; s text := gen_random_uuid()::text;
begin
  if exists (select 1 from bh.nhan_vien) then perform bh.loi('Cửa hàng đã có tài khoản chủ.'); end if;
  insert into bh.nhan_vien (ten_dang_nhap, ho_ten, salt, hash, la_chu)
    values (bh.ten_dn(d->>'tenDangNhap'), coalesce(nullif(bh.chu(d->>'hoTen'), ''), 'Chủ cửa hàng'), s, bh.tao_hash(bh.kt_mk(d->>'matKhau')), true)
    returning * into r;
  perform bh.nhat_ky_(r, 'Tạo tài khoản chủ', r.ten_dang_nhap);
  return jsonb_build_object('tk', bh.tao_phien(r));
end $$;

-- trả về {ok,...} trực tiếp (không ném lỗi) để số lần nhập sai được ghi lại
create or replace function bh.dang_nhap(d jsonb) returns jsonb language plpgsql as $$
declare ten_ text := lower(bh.chu(d->>'tenDangNhap')); r bh.nhan_vien; sai int;
begin
  delete from bh.sai_dn where het < bh.bay_gio();
  select so into sai from bh.sai_dn where sai_dn.ten = ten_;
  if coalesce(sai, 0) >= 5 then return jsonb_build_object('ok', false, 'error', 'Nhập sai quá nhiều lần. Vui lòng thử lại sau 10 phút.'); end if;
  select * into r from bh.nhan_vien where ten_dang_nhap = ten_;
  if not found or not bh.dung_mk(r, d->>'matKhau') then
    insert into bh.sai_dn (ten, so, het) values (ten_, 1, bh.bay_gio() + 600000)
      on conflict (ten) do update set so = bh.sai_dn.so + 1, het = excluded.het;
    return jsonb_build_object('ok', false, 'error', 'Sai tên đăng nhập hoặc mật khẩu.');
  end if;
  if r.bi_khoa then return jsonb_build_object('ok', false, 'error', 'Tài khoản này đang bị khoá.'); end if;
  delete from bh.sai_dn where sai_dn.ten = ten_;
  if r.hash not like '$2%' then update bh.nhan_vien set hash = bh.tao_hash(d->>'matKhau') where id = r.id returning * into r; end if;
  return jsonb_build_object('ok', true, 'data', jsonb_build_object('tk', bh.tao_phien(r)));
end $$;

/* ====================== CÁC CHỨC NĂNG ====================== */

create or replace function bh.v_khoi_dong(u bh.nhan_vien, d jsonb) returns jsonb language sql stable as $$
  select jsonb_build_object('toi', bh.nv_cong(u), 'quyenDS', bh.quyen_ds(), 'caiDat', bh.cai_dat_(),
    'hang', coalesce((select jsonb_agg(bh.hh_cong(u, p) order by p.id) from bh.hang_hoa p), '[]'::jsonb),
    'khach', coalesce((select jsonb_agg(bh.kh_cong(k) order by k.id) from bh.khach_hang k), '[]'::jsonb),
    'doiTac', coalesce((select jsonb_agg(jsonb_build_object('id', t.id, 'ten', t.ten, 'ngung', t.ngung) order by t.id) from bh.doi_tac t), '[]'::jsonb)) $$;

/* ---------- Hàng hoá ---------- */
create or replace function bh.v_luu_hang(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare ten_ text := bh.chu(d->>'ten'); don_vi_ text := bh.chu(d->>'donVi'); trung text; p bh.hang_hoa;
  gia_ban_ bigint := greatest(0, bh.so(d->'giaBan')); ton_tt bigint := greatest(0, bh.so(d->'tonToiThieu')); ngung_ boolean := bh.dung(d->'ngung');
  id_ int := bh.so(d->'id'); ghi text[] := '{}'; doi boolean := false; gn bigint;
begin
  if ten_ = '' then perform bh.loi('Chưa nhập tên hàng.'); end if;
  select h.ten into trung from bh.hang_hoa h where h.id <> id_ and lower(h.ten) = lower(ten_) limit 1;
  if trung is not null then perform bh.loi('Đã có mặt hàng tên "' || trung || '".'); end if;
  if id_ <> 0 then
    select * into p from bh.hang_hoa where id = id_;
    if not found then perform bh.loi('Không tìm thấy mặt hàng.'); end if;
    if ten_ <> p.ten or don_vi_ <> p.don_vi or ton_tt <> p.ton_toi_thieu or ngung_ <> p.ngung then
      perform bh.can(u, 'suaHang');
      if ten_ <> p.ten then ghi := ghi || ('tên: ' || p.ten || ' → ' || ten_); end if;
      if ngung_ <> p.ngung then ghi := ghi || (case when ngung_ then 'ngừng bán' else 'bán lại' end); end if;
      doi := true;
    end if;
    if gia_ban_ <> p.gia_ban then perform bh.can(u, 'suaGia'); ghi := ghi || ('giá bán: ' || p.gia_ban || ' → ' || gia_ban_); doi := true; end if;
    gn := p.gia_nhap;
    if bh.co_gt(d->'giaNhap') and bh.co(u, 'xemGiaNhap') then
      gn := greatest(0, bh.so(d->'giaNhap'));
      if gn <> p.gia_nhap then perform bh.can(u, 'suaGia'); ghi := ghi || ('giá nhập: ' || p.gia_nhap || ' → ' || gn); doi := true; end if;
    end if;
    if doi then
      update bh.hang_hoa h set ten = ten_, don_vi = don_vi_, ton_toi_thieu = ton_tt, ngung = ngung_,
        gia_ban = gia_ban_, gia_nhap = gn where h.id = id_ returning * into p;
      perform bh.nhat_ky_(u, 'Sửa mặt hàng', p.ten || case when cardinality(ghi) > 0 then ' (' || array_to_string(ghi, '; ') || ')' else '' end);
    end if;
  else
    perform bh.can(u, 'suaHang');
    insert into bh.hang_hoa (ten, don_vi, gia_ban, gia_nhap, ton_toi_thieu)
      values (ten_, don_vi_, gia_ban_, case when bh.co(u, 'xemGiaNhap') then greatest(0, bh.so(d->'giaNhap')) else 0 end, ton_tt) returning * into p;
    perform bh.nhat_ky_(u, 'Thêm mặt hàng', ten_ || ' - giá bán ' || gia_ban_);
  end if;
  return jsonb_build_object('hang', jsonb_build_array(bh.hh_cong(u, p)));
end $$;

/* ---------- Khách hàng ---------- */

create or replace function bh.v_xoa_khach(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare k bh.khach_hang; xoa int[] := '{}'; bo text[] := '{}'; ten_xoa text[] := '{}'; x jsonb;
begin
  if not u.la_chu then perform bh.loi('Chỉ chủ cửa hàng mới được xoá khách.'); end if;
  if jsonb_typeof(d->'ids') <> 'array' or jsonb_array_length(d->'ids') = 0 then perform bh.loi('Chưa chọn khách nào.'); end if;
  for x in select * from jsonb_array_elements(d->'ids') loop
    select * into k from bh.khach_hang where id = bh.so(x);
    if not found then continue; end if;
    if k.no <> 0 then bo := bo || k.ten; continue; end if;
    delete from bh.khach_hang where id = k.id;
    xoa := xoa || k.id; ten_xoa := ten_xoa || (k.ten || case when k.sdt <> '' then ' (' || k.sdt || ')' else '' end);
  end loop;
  if cardinality(xoa) > 0 then
    perform bh.nhat_ky_(u, 'Xoá khách hàng', cardinality(xoa) || ' khách: ' || array_to_string(ten_xoa, '; '));
  end if;
  return jsonb_build_object('xoa', to_jsonb(xoa), 'boQua', to_jsonb(bo));
end $$;
create or replace function bh.v_luu_khach(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare ten_ text := bh.chu(d->>'ten'); sdt_ text := regexp_replace(bh.chu(d->>'sdt'), '[^\d+]', '', 'g'); dia_chi_ text := bh.chu(d->>'diaChi');
  id_ int := bh.so(d->'id'); han_muc_ bigint := greatest(0, bh.so(d->'hanMuc')); k bh.khach_hang; trung text; no_ bigint;
begin
  if ten_ = '' then perform bh.loi('Chưa nhập tên khách.'); end if;
  select x.ten into trung from bh.khach_hang x where x.id <> id_ and lower(x.ten) = lower(ten_) and x.sdt = sdt_ limit 1;
  if trung is not null then perform bh.loi('Đã có khách "' || trung || '" với số điện thoại này.'); end if;
  if id_ <> 0 then
    select * into k from bh.khach_hang where id = id_;
    if not found then perform bh.loi('Không tìm thấy khách hàng.'); end if;
    if han_muc_ <> k.han_muc then
      perform bh.can(u, 'hanMuc');
      perform bh.nhat_ky_(u, 'Sửa hạn mức nợ', k.ten || ': ' || k.han_muc || ' → ' || han_muc_);
    end if;
    if bh.co_gt(d->'ngung') and bh.dung(d->'ngung') <> k.ngung then perform bh.chu1(u); end if;
    update bh.khach_hang x set ten = ten_, sdt = sdt_, dia_chi = dia_chi_, han_muc = han_muc_,
      ngung = case when bh.co_gt(d->'ngung') then bh.dung(d->'ngung') else x.ngung end
      where x.id = id_ returning * into k;
  else
    if han_muc_ > 0 then perform bh.can(u, 'hanMuc'); end if;
    no_ := bh.so(d->'noDauKy');
    if no_ <> 0 then perform bh.chu1(u); end if;
    insert into bh.khach_hang (ten, sdt, dia_chi, han_muc, no) values (ten_, sdt_, dia_chi_, han_muc_, no_) returning * into k;
    perform bh.nhat_ky_(u, 'Thêm khách hàng', ten_ || case when no_ <> 0 then ' - nợ đầu kỳ ' || no_ else '' end);
  end if;
  return jsonb_build_object('khach', jsonb_build_array(bh.kh_cong(k)));
end $$;

create or replace function bh.v_dieu_chinh_no(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare k bh.khach_hang; cu bigint; moi bigint := bh.so(d->'noMoi');
begin
  perform bh.chu1(u);
  select * into k from bh.khach_hang where id = bh.so(d->'khId');
  if not found then perform bh.loi('Không tìm thấy khách hàng.'); end if;
  cu := k.no;
  update bh.khach_hang set no = moi where id = k.id returning * into k;
  perform bh.nhat_ky_(u, 'Điều chỉnh nợ khách', k.ten || ': ' || cu || ' → ' || moi ||
    case when bh.dung(d->'ghiChu') then ' (' || bh.chu(d->>'ghiChu') || ')' else '' end);
  return jsonb_build_object('khach', jsonb_build_array(bh.kh_cong(k)));
end $$;

create or replace function bh.v_chi_tiet_khach(u bh.nhan_vien, d jsonb) returns jsonb language sql stable as $$
  select jsonb_build_object('lichSu', coalesce((select jsonb_agg(x.o order by x.t desc) from (
    select o, t from (
      select bh.hd_cong(u, r) o, r.thoi_gian t from bh.hoa_don r where r.kh_id = bh.so(d->'id') and r.trang_thai = 'OK'
      union all
      select bh.thu_cong(r), r.thoi_gian from bh.thu_no r where r.kh_id = bh.so(d->'id') and r.trang_thai = 'OK'
    ) a order by t desc limit 200) x), '[]'::jsonb)) $$;

/* ---------- Bán hàng / trả hàng ---------- */
-- huỷ hoá đơn: trả lại tồn kho và nợ; trả về {hang: [id...], khId}
create or replace function bh.huy_hd(hd bh.hoa_don) returns jsonb language plpgsql as $$
declare dau int := case when hd.loai = 'TRA' then -1 else 1 end; it jsonb; ids int[] := '{}';
begin
  if hd.trang_thai <> 'OK' then perform bh.loi('Hoá đơn này đã huỷ rồi.'); end if;
  for it in select * from jsonb_array_elements(hd.items) loop
    update bh.hang_hoa set ton = ton + dau * bh.so(it->'sl') where id = bh.so(it->'id');
    if found then ids := ids || bh.so(it->'id')::int; end if;
  end loop;
  if hd.kh_id <> 0 then update bh.khach_hang set no = no - (hd.con_no - hd.no_cu) where id = hd.kh_id; end if;
  update bh.hoa_don set trang_thai = 'HUY' where id = hd.id;
  return jsonb_build_object('hang', to_jsonb(ids), 'khId', hd.kh_id);
end $$;

create or replace function bh.v_luu_ban(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare loai text := case when d->>'loai' = 'TRA' then 'TRA' else 'BAN' end;
  sua_id int := bh.so(d->'suaId'); cu bh.hoa_don; k bh.khach_hang; co_k boolean := false; p bh.hang_hoa; it jsonb;
  ids int[] := '{}'; sls bigint[] := '{}'; gias bigint[] := '{}'; tong bigint := 0; sl bigint; gia bigint; giam bigint; phai_tra bigint;
  no_ht bigint := 0; tt bigint; con_no bigint; ds_hang int[] := '{}'; h jsonb; items jsonb := '[]'; mo_ta text[] := '{}';
  hd bh.hoa_don; thoi_gian bigint := bh.bay_gio(); i int; ghi_chu text; kq jsonb; kc bh.khach_hang;
begin
  if sua_id <> 0 then
    perform bh.can(u, 'suaHoaDon');
    select * into cu from bh.hoa_don where id = sua_id;
    if not found then perform bh.loi('Không tìm thấy hoá đơn cần sửa.'); end if;
    if cu.loai <> loai then perform bh.loi('Không đổi được loại hoá đơn khi sửa.'); end if;
  end if;
  if jsonb_typeof(d->'items') is distinct from 'array' or jsonb_array_length(d->'items') = 0 then perform bh.loi('Chưa chọn mặt hàng nào.'); end if;
  for it in select * from jsonb_array_elements(d->'items') loop
    select * into p from bh.hang_hoa where id = bh.so(it->'id');
    if not found then perform bh.loi('Không tìm thấy mặt hàng (mã ' || coalesce(it->>'id', '') || ').'); end if;
    sl := bh.so(it->'sl');
    if sl <= 0 then perform bh.loi('Số lượng của "' || p.ten || '" phải lớn hơn 0.'); end if;
    if p.id = any(ids) then perform bh.loi('Mặt hàng "' || p.ten || '" bị lặp lại trong đơn.'); end if;
    gia := p.gia_ban;
    if bh.co_gt(it->'gia') and bh.so(it->'gia') <> p.gia_ban then perform bh.can(u, 'suaGia'); gia := greatest(0, bh.so(it->'gia')); end if;
    ids := ids || p.id; sls := sls || sl; gias := gias || gia;
    tong := tong + sl * gia;
  end loop;
  giam := least(greatest(0, bh.so(d->'giamGia')), tong); phai_tra := tong - giam;
  if bh.dung(d->'khId') then
    select * into k from bh.khach_hang where id = bh.so(d->'khId');
    if not found then perform bh.loi('Không tìm thấy khách hàng.'); end if;
    co_k := true; no_ht := k.no;
  end if;
  if cu.id is not null and co_k and cu.kh_id = k.id then no_ht := no_ht - (cu.con_no - cu.no_cu); end if;
  tt := bh.so(d->'thanhToan');
  if loai = 'BAN' then
    if not co_k then tt := phai_tra; end if;
    if tt < 0 then perform bh.loi('Số tiền khách trả không hợp lệ.'); end if;
    if tt > phai_tra + greatest(no_ht, 0) then perform bh.loi('Khách trả nhiều hơn tổng tiền hàng và nợ cũ.'); end if;
    con_no := no_ht + phai_tra - tt;
    if co_k and k.han_muc > 0 and con_no > k.han_muc and con_no > no_ht then
      if not bh.co(u, 'vuotHanMuc') then perform bh.loi('Khách "' || k.ten || '" sẽ vượt hạn mức nợ. Bạn chưa được cấp quyền cho mua vượt hạn mức.'); end if;
      if not bh.dung(d->'choVuot') then perform bh.loi('Khách sẽ vượt hạn mức nợ, cần xác nhận.'); end if;
    end if;
  else
    if not co_k then tt := phai_tra; end if;
    if tt < 0 or tt > phai_tra then perform bh.loi('Số tiền hoàn cho khách không hợp lệ.'); end if;
    con_no := no_ht - (phai_tra - tt);
  end if;
  /* bắt đầu ghi */
  if cu.id is not null then
    h := bh.huy_hd(cu);
    select array_agg(x::int) into ds_hang from jsonb_array_elements_text(h->'hang') x;
    ds_hang := coalesce(ds_hang, '{}');
    thoi_gian := cu.thoi_gian;
  end if;
  for i in 1 .. coalesce(array_length(ids, 1), 0) loop
    update bh.hang_hoa set ton = ton + case when loai = 'BAN' then -sls[i] else sls[i] end where id = ids[i] returning * into p;
    if not (p.id = any(ds_hang)) then ds_hang := ds_hang || p.id; end if;
    items := items || jsonb_build_array(jsonb_build_object('id', p.id, 'ten', p.ten, 'dv', p.don_vi, 'sl', sls[i], 'gia', gias[i], 'von', p.gia_nhap));
    mo_ta := mo_ta || (p.ten || ' x' || sls[i]);
  end loop;
  if co_k then update bh.khach_hang set no = con_no where id = k.id returning * into k; end if;
  ghi_chu := bh.chu(d->>'ghiChu');
  if cu.id is not null then ghi_chu := ghi_chu || case when ghi_chu <> '' then ' ' else '' end || '[sửa từ #' || cu.id || ']'; end if;
  insert into bh.hoa_don (loai, thoi_gian, kh_id, kh_ten, kh_sdt, kh_dia_chi, tong, giam_gia, no_cu, thanh_toan, con_no, nhan_vien, trang_thai, ghi_chu, chi_tiet, items)
    values (loai, thoi_gian, case when co_k then k.id else 0 end, case when co_k then k.ten else 'Khách lẻ' end, case when co_k then k.sdt else '' end,
      case when co_k then k.dia_chi else '' end, tong, giam, no_ht, tt, con_no, u.ho_ten, 'OK', ghi_chu, array_to_string(mo_ta, '; '), items)
    returning * into hd;
  if cu.id is not null then
    perform bh.nhat_ky_(u, 'Sửa hoá đơn', '#' || cu.id || ' → #' || hd.id || ' | cũ: ' || cu.chi_tiet || ' (' || (cu.tong - cu.giam_gia) || ') | mới: ' || hd.chi_tiet || ' (' || phai_tra || ')');
  end if;
  if loai = 'TRA' then perform bh.nhat_ky_(u, 'Trả hàng', '#' || hd.id || ' ' || hd.kh_ten || ': ' || hd.chi_tiet || ' (' || phai_tra || ')'); end if;
  kq := jsonb_build_object('hd', bh.hd_cong(u, hd),
    'hang', coalesce((select jsonb_agg(bh.hh_cong(u, x)) from bh.hang_hoa x where x.id = any(ds_hang)), '[]'::jsonb),
    'khach', case when co_k then jsonb_build_array(bh.kh_cong(k)) else '[]'::jsonb end);
  if cu.id is not null and cu.kh_id <> 0 and (not co_k or cu.kh_id <> k.id) then
    select * into kc from bh.khach_hang where id = cu.kh_id;
    if found then kq := jsonb_set(kq, '{khach}', (kq->'khach') || jsonb_build_array(bh.kh_cong(kc))); end if;
  end if;
  return kq;
end $$;

create or replace function bh.v_huy_hoa_don(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare hd bh.hoa_don; h jsonb; k bh.khach_hang;
begin
  perform bh.can(u, 'suaHoaDon');
  select * into hd from bh.hoa_don where id = bh.so(d->'id');
  if not found then perform bh.loi('Không tìm thấy hoá đơn.'); end if;
  h := bh.huy_hd(hd);
  perform bh.nhat_ky_(u, 'Huỷ hoá đơn', '#' || hd.id || ' ' || hd.kh_ten || ': ' || hd.chi_tiet || ' (' || (hd.tong - hd.giam_gia) || ')' ||
    case when bh.dung(d->'lyDo') then ' | lý do: ' || bh.chu(d->>'lyDo') else '' end);
  select * into k from bh.khach_hang where id = hd.kh_id;
  return jsonb_build_object(
    'hang', coalesce((select jsonb_agg(bh.hh_cong(u, x)) from bh.hang_hoa x where x.id in (select (y)::int from jsonb_array_elements_text(h->'hang') y)), '[]'::jsonb),
    'khach', case when k.id is not null then jsonb_build_array(bh.kh_cong(k)) else '[]'::jsonb end);
end $$;

/* ---------- Thu nợ ---------- */
create or replace function bh.v_thu_no(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare k bh.khach_hang; tien bigint := bh.so(d->'soTien'); no_cu bigint; r bh.thu_no; p jsonb;
begin
  select * into k from bh.khach_hang where id = bh.so(d->'khId');
  if not found then perform bh.loi('Không tìm thấy khách hàng.'); end if;
  if tien <= 0 then perform bh.loi('Số tiền thu phải lớn hơn 0.'); end if;
  if tien > k.no then perform bh.loi('Khách chỉ đang nợ ' || k.no || ' đ.'); end if;
  no_cu := k.no;
  update bh.khach_hang set no = no_cu - tien where id = k.id returning * into k;
  insert into bh.thu_no (thoi_gian, kh_id, kh_ten, no_cu, so_tien, con_no, nhan_vien, trang_thai, ghi_chu)
    values (bh.bay_gio(), k.id, k.ten, no_cu, tien, no_cu - tien, u.ho_ten, 'OK', bh.chu(d->>'ghiChu')) returning * into r;
  p := bh.thu_cong(r) || jsonb_build_object('khSdt', k.sdt, 'khDiaChi', k.dia_chi);
  return jsonb_build_object('phieu', p, 'khach', jsonb_build_array(bh.kh_cong(k)));
end $$;

create or replace function bh.v_huy_thu_no(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare r bh.thu_no; k bh.khach_hang;
begin
  perform bh.can(u, 'suaHoaDon');
  select * into r from bh.thu_no where id = bh.so(d->'id');
  if not found then perform bh.loi('Không tìm thấy phiếu thu.'); end if;
  if r.trang_thai <> 'OK' then perform bh.loi('Phiếu thu này đã huỷ rồi.'); end if;
  update bh.khach_hang set no = no + r.so_tien where id = r.kh_id returning * into k;
  update bh.thu_no set trang_thai = 'HUY' where id = r.id;
  perform bh.nhat_ky_(u, 'Huỷ phiếu thu nợ', '#' || r.id || ' ' || r.kh_ten || ': ' || r.so_tien);
  return jsonb_build_object('khach', case when k.id is not null then jsonb_build_array(bh.kh_cong(k)) else '[]'::jsonb end);
end $$;

create or replace function bh.v_ds_hoa_don(u bh.nhan_vien, d jsonb) returns jsonb language sql stable as $$
  with a as (
    select bh.hd_cong(u, r) o, r.thoi_gian t from bh.hoa_don r
      where bh.trong(r.thoi_gian, d) and (r.trang_thai = 'OK' or (bh.dung(d->'gomHuy') and bh.co(u, 'suaHoaDon')))
    union all
    select bh.thu_cong(r), r.thoi_gian from bh.thu_no r
      where bh.trong(r.thoi_gian, d) and (r.trang_thai = 'OK' or (bh.dung(d->'gomHuy') and bh.co(u, 'suaHoaDon')))
  ), b as (select o, t from a order by t desc limit 501)
  select jsonb_build_object('ds', coalesce((select jsonb_agg(o order by t desc) from (select * from b order by t desc limit 500) c), '[]'::jsonb),
    'nhieuHon', (select count(*) from b) > 500) $$;

/* ---------- Nhập hàng & công nợ đối tác ---------- */
create or replace function bh.v_luu_nhap(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare dt bh.doi_tac; p bh.hang_hoa; it jsonb; xem boolean := bh.co(u, 'xemGiaNhap'); ids int[] := '{}'; sls bigint[] := '{}'; gias bigint[] := '{}';
  sl bigint; gia bigint; tong bigint := 0; items jsonb := '[]'; mo_ta text[] := '{}'; i int; r bh.phieu_nhap; hang jsonb := '[]';
begin
  perform bh.can(u, 'nhapHang');
  select * into dt from bh.doi_tac where id = bh.so(d->'dtId');
  if not found then perform bh.loi('Chưa chọn đối tác (công ty giao hàng).'); end if;
  if jsonb_typeof(d->'items') is distinct from 'array' or jsonb_array_length(d->'items') = 0 then perform bh.loi('Chưa chọn mặt hàng nào.'); end if;
  for it in select * from jsonb_array_elements(d->'items') loop
    select * into p from bh.hang_hoa where id = bh.so(it->'id');
    if not found then perform bh.loi('Không tìm thấy mặt hàng (mã ' || coalesce(it->>'id', '') || ').'); end if;
    sl := bh.so(it->'sl');
    if sl <= 0 then perform bh.loi('Số lượng của "' || p.ten || '" phải lớn hơn 0.'); end if;
    if p.id = any(ids) then perform bh.loi('Mặt hàng "' || p.ten || '" bị lặp lại trong phiếu.'); end if;
    gia := case when xem and bh.co_gt(it->'gia') then greatest(0, bh.so(it->'gia')) else p.gia_nhap end;
    ids := ids || p.id; sls := sls || sl; gias := gias || gia; tong := tong + sl * gia;
  end loop;
  for i in 1 .. array_length(ids, 1) loop
    select * into p from bh.hang_hoa where id = ids[i];
    items := items || jsonb_build_array(jsonb_build_object('id', p.id, 'ten', p.ten, 'dv', p.don_vi, 'sl', sls[i], 'gia', gias[i], 'giaCu', p.gia_nhap));
    mo_ta := mo_ta || (p.ten || ' x' || sls[i]);
    update bh.hang_hoa set ton = ton + sls[i], gia_nhap = gias[i] where id = p.id returning * into p;
    hang := hang || jsonb_build_array(bh.hh_cong(u, p));
  end loop;
  insert into bh.phieu_nhap (thoi_gian, tong, nhan_vien, trang_thai, ghi_chu, chi_tiet, items, dt_id, dt_ten)
    values (bh.bay_gio(), tong, u.ho_ten, 'OK', bh.chu(d->>'ghiChu'), array_to_string(mo_ta, '; '), items, dt.id, dt.ten) returning * into r;
  update bh.doi_tac set no = no + tong where id = dt.id;
  perform bh.nhat_ky_(u, 'Nhập hàng', '#' || r.id || ' (' || dt.ten || '): ' || r.chi_tiet);
  return jsonb_build_object('phieu', bh.nhap_cong(u, r), 'hang', hang);
end $$;

create or replace function bh.v_huy_nhap(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare r bh.phieu_nhap; it jsonb; p bh.hang_hoa; hang jsonb := '[]';
begin
  perform bh.can(u, 'nhapHang');
  select * into r from bh.phieu_nhap where id = bh.so(d->'id');
  if not found then perform bh.loi('Không tìm thấy phiếu nhập.'); end if;
  if r.trang_thai <> 'OK' then perform bh.loi('Phiếu nhập này đã huỷ rồi.'); end if;
  for it in select * from jsonb_array_elements(r.items) loop
    update bh.hang_hoa set ton = ton - bh.so(it->'sl'),
      gia_nhap = case when gia_nhap = bh.so(it->'gia') and bh.co_gt(it->'giaCu') then bh.so(it->'giaCu') else gia_nhap end
      where id = bh.so(it->'id') returning * into p;
    if found then hang := hang || jsonb_build_array(bh.hh_cong(u, p)); end if;
  end loop;
  update bh.phieu_nhap set trang_thai = 'HUY' where id = r.id;
  update bh.doi_tac set no = no - r.tong where id = coalesce(nullif(r.dt_id, 0), 1);
  perform bh.nhat_ky_(u, 'Huỷ phiếu nhập', '#' || r.id || ' (' || coalesce(nullif(r.dt_ten, ''), 'TKA') || '): ' || r.chi_tiet);
  return jsonb_build_object('hang', hang);
end $$;

create or replace function bh.v_ds_nhap(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql stable as $$
begin
  perform bh.can(u, 'nhapHang');
  return jsonb_build_object('ds', coalesce((select jsonb_agg(o order by t desc) from (
    select bh.nhap_cong(u, r) o, r.thoi_gian t from bh.phieu_nhap r where bh.trong(r.thoi_gian, d) order by r.thoi_gian desc limit 300) a), '[]'::jsonb));
end $$;

create or replace function bh.v_ds_doi_tac(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql stable as $$
begin
  perform bh.can(u, 'congNoTKA');
  return jsonb_build_object('ds', coalesce((select jsonb_agg(bh.dt_cong(r) order by r.id) from bh.doi_tac r), '[]'::jsonb));
end $$;

create or replace function bh.v_xem_doi_tac(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql stable as $$
declare dt bh.doi_tac;
begin
  perform bh.can(u, 'congNoTKA');
  select * into dt from bh.doi_tac where id = bh.so(d->'id');
  if not found then perform bh.loi('Không tìm thấy đối tác.'); end if;
  return jsonb_build_object('dt', bh.dt_cong(dt),
    'tra', coalesce((select jsonb_agg(o order by t desc) from (
      select jsonb_build_object('id', r.id, 'thoiGian', r.thoi_gian, 'soTien', r.so_tien, 'nhanVien', r.nhan_vien, 'trangThai', r.trang_thai, 'ghiChu', r.ghi_chu) o, r.thoi_gian t
      from bh.tra_doi_tac r where coalesce(nullif(r.dt_id, 0), 1) = dt.id order by r.thoi_gian desc limit 200) a), '[]'::jsonb),
    'nhap', coalesce((select jsonb_agg(o order by t desc) from (
      select (bh.nhap_cong(u, r) - 'items') || jsonb_build_object('chiTiet', r.chi_tiet) o, r.thoi_gian t
      from bh.phieu_nhap r where coalesce(nullif(r.dt_id, 0), 1) = dt.id order by r.thoi_gian desc limit 200) a), '[]'::jsonb));
end $$;

create or replace function bh.v_luu_doi_tac(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare ten_ text := bh.chu(d->>'ten'); id_ int := bh.so(d->'id'); trung text; r bh.doi_tac; no_ bigint;
begin
  perform bh.can(u, 'congNoTKA');
  if ten_ = '' then perform bh.loi('Chưa nhập tên đối tác.'); end if;
  select x.ten into trung from bh.doi_tac x where x.id <> id_ and lower(x.ten) = lower(ten_) limit 1;
  if trung is not null then perform bh.loi('Đã có đối tác tên "' || trung || '".'); end if;
  if id_ <> 0 then
    select * into r from bh.doi_tac where id = id_;
    if not found then perform bh.loi('Không tìm thấy đối tác.'); end if;
    update bh.doi_tac x set ten = ten_, sdt = bh.chu(d->>'sdt'), dia_chi = bh.chu(d->>'diaChi'),
      ngung = case when bh.co_gt(d->'ngung') then bh.dung(d->'ngung') else x.ngung end where x.id = id_ returning * into r;
    perform bh.nhat_ky_(u, 'Sửa đối tác', ten_);
  else
    no_ := bh.so(d->'noDauKy');
    if no_ <> 0 then perform bh.chu1(u); end if;
    insert into bh.doi_tac (ten, sdt, dia_chi, no) values (ten_, bh.chu(d->>'sdt'), bh.chu(d->>'diaChi'), no_) returning * into r;
    perform bh.nhat_ky_(u, 'Thêm đối tác', ten_ || case when no_ <> 0 then ' - nợ đầu kỳ ' || no_ else '' end);
  end if;
  return jsonb_build_object('ds', coalesce((select jsonb_agg(bh.dt_cong(x) order by x.id) from bh.doi_tac x), '[]'::jsonb), 'id', r.id);
end $$;

create or replace function bh.v_tra_doi_tac(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare dt bh.doi_tac; tien bigint := bh.so(d->'soTien'); r bh.tra_doi_tac;
begin
  perform bh.can(u, 'congNoTKA');
  select * into dt from bh.doi_tac where id = bh.so(d->'dtId');
  if not found then perform bh.loi('Không tìm thấy đối tác.'); end if;
  if tien <= 0 then perform bh.loi('Số tiền trả phải lớn hơn 0.'); end if;
  insert into bh.tra_doi_tac (thoi_gian, so_tien, nhan_vien, trang_thai, ghi_chu, dt_id, dt_ten)
    values (bh.bay_gio(), tien, u.ho_ten, 'OK', bh.chu(d->>'ghiChu'), dt.id, dt.ten) returning * into r;
  update bh.doi_tac set no = no - tien where id = dt.id;
  perform bh.nhat_ky_(u, 'Trả tiền đối tác', dt.ten || ' #' || r.id || ': ' || tien);
  return bh.v_xem_doi_tac(u, jsonb_build_object('id', dt.id));
end $$;

create or replace function bh.v_huy_tra_doi_tac(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare r bh.tra_doi_tac;
begin
  perform bh.can(u, 'congNoTKA');
  select * into r from bh.tra_doi_tac where id = bh.so(d->'id');
  if not found or r.trang_thai <> 'OK' then perform bh.loi('Không huỷ được phiếu này.'); end if;
  update bh.tra_doi_tac set trang_thai = 'HUY' where id = r.id;
  update bh.doi_tac set no = no + r.so_tien where id = coalesce(nullif(r.dt_id, 0), 1);
  perform bh.nhat_ky_(u, 'Huỷ phiếu trả tiền đối tác', coalesce(nullif(r.dt_ten, ''), 'TKA') || ' #' || r.id || ': ' || r.so_tien);
  return bh.v_xem_doi_tac(u, jsonb_build_object('id', coalesce(nullif(r.dt_id, 0), 1)));
end $$;

create or replace function bh.v_dat_doi_tac(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare dt bh.doi_tac;
begin
  perform bh.can(u, 'congNoTKA');
  select * into dt from bh.doi_tac where id = bh.so(d->'id');
  if not found then perform bh.loi('Không tìm thấy đối tác.'); end if;
  if bh.co_gt(d->'noMoi') then
    perform bh.chu1(u);
    perform bh.nhat_ky_(u, 'Điều chỉnh nợ đối tác', dt.ten || ': ' || dt.no || ' → ' || bh.so(d->'noMoi'));
    update bh.doi_tac set no = bh.so(d->'noMoi') where id = dt.id;
  end if;
  if d ? 'noKeToan' then
    update bh.doi_tac set no_ke_toan = case when not bh.co_gt(d->'noKeToan') or d->>'noKeToan' = '' then null else bh.so(d->'noKeToan') end where id = dt.id;
  end if;
  return bh.v_xem_doi_tac(u, jsonb_build_object('id', dt.id));
end $$;

/* ---------- Doanh số khách ---------- */
create or replace function bh.v_doanh_so_khach(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql stable as $$
declare xem boolean;
begin
  perform bh.can(u, 'xemBaoCao');
  xem := bh.co(u, 'xemGiaNhap');
  return jsonb_build_object('m', coalesce((select jsonb_object_agg(kh_id::text, o) from (
    select r.kh_id, jsonb_build_object(
      'soDon', count(*) filter (where r.loai <> 'TRA'),
      'mua', coalesce(sum(r.tong - r.giam_gia) filter (where r.loai <> 'TRA'), 0),
      'tra', coalesce(sum(r.tong - r.giam_gia) filter (where r.loai = 'TRA'), 0),
      'cuoi', coalesce(max(r.thoi_gian) filter (where r.loai <> 'TRA'), 0))
      || case when xem then jsonb_build_object('lai', coalesce(sum((case when r.loai = 'TRA' then -1 else 1 end) * (-r.giam_gia +
           coalesce((select sum((bh.so(it->'gia') - bh.so(it->'von')) * bh.so(it->'sl')) from jsonb_array_elements(r.items) it), 0))), 0)) else '{}'::jsonb end o
    from bh.hoa_don r where r.trang_thai = 'OK' and r.kh_id <> 0 and bh.trong(r.thoi_gian, d) group by r.kh_id) a), '{}'::jsonb));
end $$;

/* ---------- Kiểm kho ---------- */
create or replace function bh.v_kiem_kho(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare it jsonb; p bh.hang_hoa; thuc bigint; bg bigint := bh.bay_gio(); hang jsonb := '[]'; n int := 0;
begin
  perform bh.can(u, 'kiemKho');
  for it in select * from jsonb_array_elements(coalesce(d->'items', '[]')) loop
    select * into p from bh.hang_hoa where id = bh.so(it->'id');
    continue when not found;
    thuc := bh.so(it->'thuc');
    continue when thuc = p.ton;
    insert into bh.kiem_kho (thoi_gian, hh_id, ten, ton_so, ton_thuc, chenh_lech, nhan_vien) values (bg, p.id, p.ten, p.ton, thuc, thuc - p.ton, u.ho_ten);
    update bh.hang_hoa set ton = thuc where id = p.id returning * into p;
    hang := hang || jsonb_build_array(bh.hh_cong(u, p)); n := n + 1;
  end loop;
  if n > 0 then perform bh.nhat_ky_(u, 'Kiểm kho', 'Điều chỉnh tồn ' || n || ' mặt hàng'); end if;
  return jsonb_build_object('hang', hang);
end $$;

/* ---------- Báo cáo ---------- */
create or replace function bh.v_bao_cao(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql stable as $$
declare kq jsonb;
begin
  perform bh.can(u, 'xemBaoCao');
  with hd as (select r.*, case when r.loai = 'TRA' then -1 else 1 end dau from bh.hoa_don r where r.trang_thai = 'OK' and not r.khong_tinh_bc and bh.trong(r.thoi_gian, d)),
  it as (select hd.dau, x from hd, jsonb_array_elements(hd.items) x),
  tn as (select r.so_tien from bh.thu_no r where r.trang_thai = 'OK' and bh.trong(r.thoi_gian, d)),
  th as (select x->>'id' id, min(x->>'ten') ten, sum(dau * bh.so(x->'sl')) sl, sum(dau * bh.so(x->'sl') * bh.so(x->'gia')) tien from it group by x->>'id')
  select jsonb_build_object(
    'doanhThu', coalesce((select sum(dau * (tong - giam_gia)) from hd), 0),
    'soHD', (select count(*) from hd where dau > 0),
    'traHang', coalesce((select sum(tong - giam_gia) from hd where dau < 0), 0),
    'tienThu', coalesce((select sum(dau * thanh_toan) from hd), 0) + coalesce((select sum(so_tien) from tn), 0),
    'thuNo', coalesce((select sum(so_tien) from tn), 0),
    'banNo', coalesce((select sum(greatest(0, tong - giam_gia - thanh_toan)) from hd where dau > 0), 0),
    'loiNhuan', coalesce((select sum(dau * -giam_gia) from hd), 0) + coalesce((select sum(dau * (bh.so(x->'gia') - bh.so(x->'von')) * bh.so(x->'sl')) from it), 0),
    'thieuGiaVon', (select count(*) from it where not bh.dung(x->'von')),
    'top', coalesce((select jsonb_agg(jsonb_build_object('ten', ten, 'sl', sl, 'tien', tien) order by tien desc) from (select * from th order by tien desc limit 15) a), '[]'::jsonb))
  into kq;
  kq := kq || jsonb_build_object('cu', (select jsonb_build_object('thang', jsonb_agg(distinct thang), 'doanhThu', sum(doanh_thu), 'loiNhuan', sum(doanh_thu - von))
    from bh.slc_hang where (not bh.dung(d->'tu') or den >= bh.so(d->'tu')) and (not bh.dung(d->'den') or tu <= bh.so(d->'den')) having count(*) > 0));
  if not bh.co(u, 'xemGiaNhap') then kq := kq - 'loiNhuan' - 'thieuGiaVon'; if jsonb_typeof(kq->'cu') = 'object' then kq := jsonb_set(kq, '{cu}', (kq->'cu') - 'loiNhuan'); end if; end if;
  return kq;
end $$;

/* ---------- Số liệu cũ ---------- */
create or replace function bh.v_so_lieu_cu(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql stable as $$
declare xem boolean; th text;
begin
  perform bh.can(u, 'xemBaoCao');
  xem := bh.co(u, 'xemGiaNhap');
  th := coalesce(nullif(d->>'thang', ''), (select max(thang) from bh.slc_hang));
  return jsonb_build_object(
    'thangDS', coalesce((select jsonb_agg(jsonb_build_object('thang', thang, 'tu', tu, 'den', den) order by thang desc)
      from (select thang, min(tu) tu, max(den) den from bh.slc_hang group by thang) a), '[]'::jsonb),
    'thang', th,
    'ds', coalesce((select jsonb_agg(jsonb_build_object('ten', coalesce(h.ten, r.ten_goc), 'tenGoc', r.ten_goc, 'hhId', r.hh_id, 'sl', r.sl, 'doanhThu', r.doanh_thu)
        || case when xem then jsonb_build_object('von', r.von, 'lai', r.doanh_thu - r.von) else '{}'::jsonb end order by r.doanh_thu desc)
      from bh.slc_hang r left join bh.hang_hoa h on h.id = r.hh_id where r.thang = th), '[]'::jsonb));
end $$;

/* ---------- Nhân viên / cài đặt ---------- */
create or replace function bh.v_ds_nv(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql stable as $$
begin
  perform bh.chu1(u);
  return jsonb_build_object('ds', coalesce((select jsonb_agg(bh.nv_cong(r) order by r.id) from bh.nhan_vien r), '[]'::jsonb));
end $$;

create or replace function bh.v_luu_nv(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare ho_ten_ text := bh.chu(d->>'hoTen'); quyen_ text[]; r bh.nhan_vien; s text; ten text; kq jsonb; khoa boolean;
begin
  perform bh.chu1(u);
  if ho_ten_ = '' then perform bh.loi('Chưa nhập họ tên.'); end if;
  select coalesce(array_agg(q), '{}') into quyen_ from jsonb_array_elements_text(case when jsonb_typeof(d->'quyen') = 'array' then d->'quyen' else '[]' end) q where bh.quyen_ds() ? q;
  if bh.dung(d->'id') then
    select * into r from bh.nhan_vien where id = bh.so(d->'id');
    if not found then perform bh.loi('Không tìm thấy nhân viên.'); end if;
    khoa := (not r.la_chu) and bh.dung(d->'biKhoa');
    update bh.nhan_vien x set ho_ten = ho_ten_,
      quyen = case when x.la_chu then x.quyen else quyen_ end,
      bi_khoa = case when x.la_chu then x.bi_khoa else khoa end where x.id = r.id returning * into r;
    if bh.dung(d->'matKhau') then
      s := gen_random_uuid()::text;
      update bh.nhan_vien set salt = s, hash = bh.tao_hash(bh.kt_mk(d->>'matKhau')) where id = r.id returning * into r;
    end if;
    perform bh.nhat_ky_(u, 'Sửa nhân viên', r.ten_dang_nhap || case when bh.dung(d->'matKhau') then ' (đặt lại mật khẩu)' else '' end ||
      case when khoa then ' (khoá)' else '' end || ' | quyền: ' || case when r.la_chu then 'chủ' else array_to_string(quyen_, ',') end);
    kq := jsonb_build_object('ds', coalesce((select jsonb_agg(bh.nv_cong(x) order by x.id) from bh.nhan_vien x), '[]'::jsonb));
    if r.id = u.id and bh.dung(d->'matKhau') then kq := kq || jsonb_build_object('tk', bh.tao_phien(r)); end if;
    return kq;
  end if;
  ten := bh.ten_dn(d->>'tenDangNhap');
  if exists (select 1 from bh.nhan_vien where ten_dang_nhap = ten) then perform bh.loi('Tên đăng nhập "' || ten || '" đã có người dùng.'); end if;
  s := gen_random_uuid()::text;
  insert into bh.nhan_vien (ten_dang_nhap, ho_ten, salt, hash, la_chu, quyen) values (ten, ho_ten_, s, bh.tao_hash(bh.kt_mk(d->>'matKhau')), false, quyen_);
  perform bh.nhat_ky_(u, 'Thêm nhân viên', ten || ' | quyền: ' || array_to_string(quyen_, ','));
  return jsonb_build_object('ds', coalesce((select jsonb_agg(bh.nv_cong(x) order by x.id) from bh.nhan_vien x), '[]'::jsonb));
end $$;

create or replace function bh.v_doi_mat_khau(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare r bh.nhan_vien; s text := gen_random_uuid()::text;
begin
  select * into r from bh.nhan_vien where id = u.id;
  if not bh.dung_mk(r, d->>'cu') then perform bh.loi('Mật khẩu hiện tại không đúng.'); end if;
  update bh.nhan_vien set salt = s, hash = bh.tao_hash(bh.kt_mk(d->>'moi')) where id = r.id returning * into r;
  perform bh.nhat_ky_(u, 'Đổi mật khẩu', r.ten_dang_nhap);
  return jsonb_build_object('tk', bh.tao_phien(r));
end $$;

create or replace function bh.v_luu_cai_dat(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql as $$
declare k text;
begin
  perform bh.chu1(u);
  foreach k in array array['ten1','ten2','sdt','diaChi','loiCamOn'] loop
    if bh.co_gt(d->k) then perform bh.dat_cai_dat(k, bh.chu(d->>k)); end if;
  end loop;
  if bh.co_gt(d->'tonToiThieu') then perform bh.dat_cai_dat('tonToiThieu', greatest(0, bh.so(d->'tonToiThieu'))::text); end if;
  perform bh.nhat_ky_(u, 'Sửa cài đặt cửa hàng', '');
  return jsonb_build_object('caiDat', bh.cai_dat_());
end $$;

create or replace function bh.v_nhat_ky(u bh.nhan_vien, d jsonb) returns jsonb language plpgsql stable as $$
begin
  perform bh.chu1(u);
  return jsonb_build_object('ds', coalesce((select jsonb_agg(jsonb_build_object('thoiGian', thoi_gian, 'nhanVien', nhan_vien, 'hanhDong', hanh_dong, 'chiTiet', chi_tiet) order by id desc)
    from (select * from bh.nhat_ky order by id desc limit 300) a), '[]'::jsonb));
end $$;

/* ====================== CỬA NGÕ GỌI TỪ TRANG WEB ====================== */

create or replace function public.api(tk text, viec text, d jsonb default '{}') returns jsonb
language plpgsql security definer set search_path = bh, pg_catalog, public, extensions as $$
declare u bh.nhan_vien; ham text; kq jsonb; ma_ text; chi_doc boolean;
  ds_viec constant jsonb := '{"khoiDong":"v_khoi_dong","luuHang":"v_luu_hang","luuKhach":"v_luu_khach","xoaKhach":"v_xoa_khach","dieuChinhNo":"v_dieu_chinh_no",
    "chiTietKhach":"v_chi_tiet_khach","luuBan":"v_luu_ban","huyHoaDon":"v_huy_hoa_don","thuNo":"v_thu_no","huyThuNo":"v_huy_thu_no",
    "dsHoaDon":"v_ds_hoa_don","luuNhap":"v_luu_nhap","huyNhap":"v_huy_nhap","dsNhap":"v_ds_nhap","dsDoiTac":"v_ds_doi_tac",
    "xemDoiTac":"v_xem_doi_tac","luuDoiTac":"v_luu_doi_tac","traDoiTac":"v_tra_doi_tac","huyTraDoiTac":"v_huy_tra_doi_tac",
    "datDoiTac":"v_dat_doi_tac","doanhSoKhach":"v_doanh_so_khach","kiemKho":"v_kiem_kho","baoCao":"v_bao_cao","dsNV":"v_ds_nv",
    "luuNV":"v_luu_nv","soLieuCu":"v_so_lieu_cu","doiMatKhau":"v_doi_mat_khau","luuCaiDat":"v_luu_cai_dat","nhatKy":"v_nhat_ky"}';
  ds_chi_doc constant text[] := array['khoiDong','chiTietKhach','dsHoaDon','dsNhap','dsDoiTac','xemDoiTac','doanhSoKhach','baoCao','dsNV','nhatKy','soLieuCu'];
  ds_ma constant text[] := array['luuBan','thuNo','luuNhap','traDoiTac'];
begin
  d := coalesce(d, '{}');
  if jsonb_typeof(d) <> 'object' then d := '{}'; end if;
  chi_doc := viec = any(ds_chi_doc);
  if not chi_doc then perform pg_advisory_xact_lock(424242); end if;
  if viec = 'trangThai' then return jsonb_build_object('ok', true, 'data', jsonb_build_object('chuaCoChu', not exists (select 1 from bh.nhan_vien))); end if;
  if viec = 'dangNhap' then return bh.dang_nhap(d); end if;
  begin
    if viec = 'taoChu' then return jsonb_build_object('ok', true, 'data', bh.tao_chu(d)); end if;
    u := bh.xac_thuc(tk);
    if u.id is null then return jsonb_build_object('ok', false, 'hetPhien', true, 'error', 'Vui lòng đăng nhập lại.'); end if;
    if viec = 'dangXuat' then delete from bh.phien where phien.tk = api.tk; return jsonb_build_object('ok', true, 'data', '{}'::jsonb); end if;
    if viec = 'xuatSheet' then perform bh.loi('Bản web mới không tạo Google Sheet. Hãy dùng nút "Tải file Excel về máy".'); end if;
    ham := ds_viec ->> viec;
    if ham is null then perform bh.loi('Không có chức năng: ' || coalesce(viec, '')); end if;
    if viec = any(ds_ma) and bh.dung(d->'_ma') then
      ma_ := left(d->>'_ma', 60);
      select m.kq into kq from bh.ma_da_lam m where m.ma = ma_;
      if kq is not null then return kq; end if;
    end if;
    execute format('select bh.%I($1, $2)', ham) into kq using u, d;
    kq := jsonb_build_object('ok', true, 'data', kq);
    if ma_ is not null then
      delete from bh.ma_da_lam where luc < bh.bay_gio() - 21600000;
      insert into bh.ma_da_lam (ma, kq, luc) values (ma_, kq, bh.bay_gio()) on conflict (ma) do nothing;
    end if;
    return kq;
  exception
    when sqlstate 'BH001' then return jsonb_build_object('ok', false, 'error', sqlerrm);
    when others then return jsonb_build_object('ok', false, 'error', 'Lỗi hệ thống: ' || sqlerrm);
  end;
end $$;

revoke all on all functions in schema bh from public;
revoke all on function public.api(text, text, jsonb) from public;
do $$ begin
  if exists (select 1 from pg_roles where rolname = 'anon') then
    execute 'revoke all on all functions in schema bh from anon, authenticated';
    execute 'grant execute on function public.api(text, text, jsonb) to anon, authenticated';
  end if;
end $$;
