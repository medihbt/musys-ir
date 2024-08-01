namespace Musys {
    public size_t hash_combine2(size_t h0, size_t h1) {
        return h0 ^ (h1 + 0x9e3779b9 + (h0 << 6) + (h0 >> 2));
    }
    public size_t hash_combine3(size_t h0, size_t h1, size_t h2) {
        return hash_combine2(h0, hash_combine2(h1, h2));
    }
}