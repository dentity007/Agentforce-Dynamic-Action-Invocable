public with sharing class PlatformCacheOffloadProvider implements MemoryOffloadService.OffloadProvider {
    private static final String PARTITION = 'Agentforce';

    public OffloadModels.Ref put(String payload) {
        try {
            String key = Crypto.getRandomUUID();
            Cache.Session s = Cache.Session.getCache(PARTITION);
            if (s == null) return null;
            s.put(key, payload);
            OffloadModels.Ref r = new OffloadModels.Ref();
            r.store = 'PlatformCache';
            r.key = key;
            r.sizeBytes = Blob.valueOf(payload).size();
            return r;
        } catch (Exception e) {
            return null;
        }
    }

    public String get(String key) {
        try {
            Cache.Session s = Cache.Session.getCache(PARTITION);
            if (s == null) return null;
            Object v = s.get(key);
            return (v == null) ? null : String.valueOf(v);
        } catch (Exception e) {
            return null;
        }
    }

    public void remove(String key) {
        try {
            Cache.Session s = Cache.Session.getCache(PARTITION);
            if (s != null) s.remove(key);
        } catch (Exception e) {
        }
    }

    public Integer size(String key) {
        String v = get(key);
        return (v == null) ? 0 : Blob.valueOf(v).size();
    }
}

