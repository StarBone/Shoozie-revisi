import mysql from 'mysql2'
import bcrypt from 'bcryptjs';

import dotenv from 'dotenv'
dotenv.config()

const pool = mysql.createPool({
  host: process.env.MYSQL_HOST,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  database: process.env.MYSQL_DATABASE
}).promise()

// login
export async function loginUser(email, password) {
  const [rows] = await pool.query(`SELECT * FROM user WHERE email_user = ?`, [email]);
  const user = rows[0];

  if (!user) {
    throw new Error("Email tidak ditemukan");
  }

  const isMatch = await bcrypt.compare(password, user.password_hash);
  if (!isMatch) {
    throw new Error("Password salah");
  }

  // Jangan kembalikan hash password
  delete user.password_hash;
  return user;
}

// Get Product
export async function getProducts() {
  const [rows] = await pool.query("SELECT * FROM produk")
  return rows
}

export async function getProduct(idProduct) {
  const [rows] = await pool.query(`
  SELECT * 
  FROM produk
  WHERE id_product = ?
  `, [idProduct])
  return rows[0]
}

export async function getProductsByKategori(id_kategori) {
  if (!id_kategori) {
    const [rows] = await pool.query("SELECT * FROM produk");
    return rows;
  }
  const [rows] = await pool.query("SELECT * FROM produk WHERE id_kategori = ?", [id_kategori]);
  return rows;
}

export async function updateFavoritProduct(idProduct, favoritValue) {
  const [result] = await pool.query(`
    UPDATE produk
    SET favorit_product = ?
    WHERE id_product = ?
  `, [favoritValue, idProduct])
  return result;
}

// Get User
export async function getUsers() {
  const [rows] = await pool.query("SELECT * FROM user")
  console.log('data user = ', rows);
  return rows
}

export async function getUser(idUser) {
  const [rows] = await pool.query(`
  SELECT * 
  FROM user
  WHERE id_user = ?
  `, [idUser])
  return rows[0]
}

export async function addUser(user) {
  const {
    nama_user,
    jeniskelamin_user,
    tgllahir_user,
    alamat_user,
    nohp_user,
    email_user,
    password
  } = user;

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10);

  // Insert ke database
  const [result] = await pool.query(`
    INSERT INTO user (
      nama_user, jeniskelamin_user, tgllahir_user,
      alamat_user, nohp_user, email_user, password_hash
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
  `, [
    nama_user,
    jeniskelamin_user,
    tgllahir_user,
    alamat_user,
    nohp_user,
    email_user,
    hashedPassword
  ]);

  return {
    id_user: result.insertId,
    ...user,
    password: undefined
  };
}

// Add Keranjang
export async function addToKeranjang(data) {
  const { id_product, id_kategori, id_user, jumlah, id_varian } = data;
  const tanggal_ditambahkan = new Date();

  const [cek] = await pool.query(
    `SELECT * FROM keranjang WHERE id_user = ? AND id_product = ? AND id_varian = ?`,
    [id_user, id_product, id_varian]
  );

  if (cek.length > 0) {
    const jumlahBaru = cek[0].jumlah + (jumlah || 1);
    await pool.query(
      `UPDATE keranjang SET jumlah = ? WHERE id_user = ? AND id_product = ? AND id_varian = ?`,
      [jumlahBaru, id_user, id_product, id_varian]
    );
    return {
      id_keranjang: cek[0].id_keranjang,
      id_product,
      id_kategori: cek[0].id_kategori,
      id_user,
      id_varian,
      jumlah: jumlahBaru,
      tanggal_ditambahkan: cek[0].tanggal_ditambahkan
    };
  } else {
    const [result] = await pool.query(
      `INSERT INTO keranjang (
        id_product, id_kategori, id_user, jumlah, tanggal_ditambahkan, id_varian
      ) VALUES (?, ?, ?, ?, ?, ?)`,
      [id_product, id_kategori, id_user, jumlah, tanggal_ditambahkan, id_varian]
    );
    return {
      id_keranjang: result.insertId,
      ...data,
      tanggal_ditambahkan
    };
  }
}

export async function getUserKeranjang(id_user) {
  const [rows] = await pool.query(`
    SELECT k.*, 
           p.nama_product, p.harga_product, p.nohp_seller,
           vp.warna, vp.ukuran, vp.gambar_cart, vp.stok
    FROM keranjang k
    JOIN produk p ON k.id_product = p.id_product
    LEFT JOIN varian_produk vp ON k.id_varian = vp.id_varian
    WHERE k.id_user = ? AND (vp.stok IS NULL OR vp.stok > 0)
  `, [id_user]);
  return rows;
}


// Update jumlah keranjang
export async function updateJumlahKeranjang(id_user, id_product, id_varian, jumlah) {
  if (jumlah <= 0) {
    // Hapus item jika jumlah <= 0
    const [result] = await pool.query(`
      DELETE FROM keranjang
      WHERE id_user = ? AND id_product = ? AND id_varian = ?
    `, [id_user, id_product, id_varian]);
    return { deleted: true, affectedRows: result.affectedRows };
  } else {
    // Cek apakah sudah ada item di keranjang
    const [cek] = await pool.query(
      `SELECT * FROM keranjang WHERE id_user = ? AND id_product = ? AND id_varian = ?`,
      [id_user, id_product, id_varian]
    );
    if (cek.length === 0) {
      // Jika belum ada, insert baru
      const tanggal_ditambahkan = new Date();
      const [result] = await pool.query(`
        INSERT INTO keranjang (id_product, id_kategori, id_user, jumlah, tanggal_ditambahkan, id_varian)
        VALUES (?, (SELECT id_kategori FROM produk WHERE id_product = ?), ?, ?, ?, ?)`,
        [id_product, id_product, id_user, jumlah, tanggal_ditambahkan, id_varian]
      );
      return { deleted: false, affectedRows: result.affectedRows };
    } else {
      // Jika sudah ada, update jumlah
      const [result] = await pool.query(`
        UPDATE keranjang
        SET jumlah = ?
        WHERE id_user = ? AND id_product = ? AND id_varian = ?
      `, [jumlah, id_user, id_product, id_varian]);
      return { deleted: false, affectedRows: result.affectedRows };
    }
  }
}

// Update User Name
export async function updateUserName(idUser, nama_user) {
  const [result] = await pool.query(
    `UPDATE user SET nama_user = ? WHERE id_user = ?`,
    [nama_user, idUser]
  );
  return result;
}

// Update User Address
export async function updateUserAddress(idUser, alamat_user) {
  const [result] = await pool.query(
    `UPDATE user SET alamat_user = ? WHERE id_user = ?`,
    [alamat_user, idUser]
  );
  return result;
}

// Update User Phone Number
export async function updateUserPhone(idUser, nohp_user) {
  const [result] = await pool.query(
    `UPDATE user SET nohp_user = ? WHERE id_user = ?`,
    [nohp_user, idUser]
  );
  return result;
}

// Update User Gender
export async function updateUserGender(idUser, jeniskelamin_user) {
  const [result] = await pool.query(
    `UPDATE user SET jeniskelamin_user = ? WHERE id_user = ?`,
    [jeniskelamin_user, idUser]
  );
  return result;
}

// Update User Birthdate
export async function updateUserBirthdate(idUser, tgllahir_user) {
  const [result] = await pool.query(
    `UPDATE user SET tgllahir_user = ? WHERE id_user = ?`,
    [tgllahir_user, idUser]
  );
  return result;
}

// Tambahkan produk ke favorit user
export async function addFavoritProduct(idUser, idProduct) {
  const [result] = await pool.query(`
    INSERT IGNORE INTO favorit (id_user, id_product)
    VALUES (?, ?)
  `, [idUser, idProduct]);
  return result;
}

// Hapus produk dari favorit user
export async function removeFavoritProduct(idUser, idProduct) {
  const [result] = await pool.query(`
    DELETE FROM favorit
    WHERE id_user = ? AND id_product = ?
  `, [idUser, idProduct]);
  return result;
}

// Ambil semua produk favorit user
export async function getUserFavoritProducts(idUser) {
  // Ambil produk favorit beserta gambar_produk dari varian_produk (ambil varian pertama)
  const [rows] = await pool.query(`
    SELECT p.*, 
           (SELECT vp.gambar_produk FROM varian_produk vp WHERE vp.id_product = p.id_product LIMIT 1) AS gambar_produk
    FROM favorit f
    JOIN produk p ON f.id_product = p.id_product
    WHERE f.id_user = ?
  `, [idUser]);
  return rows;
}

// Get Product Variants
export async function getProductVariants(idProduct) {
  const [rows] = await pool.query(`
    SELECT * FROM varian_produk WHERE id_product = ?
  `, [idProduct]);
  return rows;
}

//Web admin

// Tambah produk
export async function addProduct(data) {
  const { nama_product, harga_product, favorit_product, nohp_seller, id_kategori } = data;
  const [result] = await pool.query(`
    INSERT INTO produk (nama_product, harga_product, favorit_product, nohp_seller, id_kategori)
    VALUES (?, ?, ?, ?, ?)
  `, [nama_product, harga_product, favorit_product || 0, nohp_seller, id_kategori]);

  return result.insertId;
}

// Tambah varian produk
export async function addProductVariant(data) {
  const { id_product, warna, ukuran, gambar_produk, gambar_detail, gambar_cart } = data;
  const [result] = await pool.query(`
    INSERT INTO varian_produk (id_product, warna, ukuran, gambar_produk, gambar_detail, gambar_cart)
    VALUES (?, ?, ?, ?, ?, ?)
  `, [id_product, warna, ukuran, gambar_produk, gambar_detail, gambar_cart]);

  return result.insertId;
}

// Update stok varian produk (set langsung)
export async function updateVariantStock(id_varian, newStock) {
  const [result] = await pool.query(
    `UPDATE varian_produk SET stok = ? WHERE id_varian = ?`,
    [newStock, id_varian]
  );
  return result;
}

// Tambah stok varian produk
export async function increaseVariantStock(id_varian, amount) {
  const [result] = await pool.query(
    `UPDATE varian_produk SET stok = stok + ? WHERE id_varian = ?`,
    [amount, id_varian]
  );
  return result;
}

// Kurangi stok varian produk
export async function decreaseVariantStock(id_varian, amount) {
  const [result] = await pool.query(
    `UPDATE varian_produk SET stok = GREATEST(stok - ?, 0) WHERE id_varian = ?`,
    [amount, id_varian]
  );
  return result;
}