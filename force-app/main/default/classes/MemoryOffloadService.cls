public with sharing class MemoryOffloadService {
    public interface OffloadProvider {
        OffloadModels.Ref put(String payload);
        String get(String key);
        void remove(String key);
        Integer size(String key);
    }

    public static OffloadModels.Ref tryOffload(String store, String payload) {
        if (String.isBlank(payload)) return null;
        try {
            OffloadProvider p = resolve(store);
            if (p == null) return null;
            return p.put(payload);
        } catch (Exception e) {
            return null; // fail-soft
        }
    }

    public static String tryFetch(String store, String key) {
        try {
            OffloadProvider p = resolve(store);
            return (p == null) ? null : p.get(key);
        } catch (Exception e) {
            return null;
        }
    }

    private static OffloadProvider resolve(String store) {
        String s = String.isBlank(store) ? 'ContentVersion' : store;
        if (s == 'PlatformCache') return new PlatformCacheOffloadProvider();
        if (s == 'ContentVersion') return new ContentVersionOffloadProvider();
        return null;
    }
}

