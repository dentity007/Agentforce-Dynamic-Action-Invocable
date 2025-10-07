public with sharing class ContentVersionOffloadProvider implements MemoryOffloadService.OffloadProvider {
    private static final String PREFIX = 'MOff-';

    public OffloadModels.Ref put(String payload) {
        try {
            String key = PREFIX + Crypto.getRandomUUID();
            ContentVersion cv = new ContentVersion();
            cv.Title = key;
            cv.PathOnClient = key + '.json';
            cv.VersionData = Blob.valueOf(payload);
            insert cv;
            OffloadModels.Ref r = new OffloadModels.Ref();
            r.store = 'ContentVersion';
            r.key = (String) cv.Id;
            r.sizeBytes = cv.VersionData != null ? cv.VersionData.size() : Blob.valueOf(payload).size();
            return r;
        } catch (Exception e) {
            return null;
        }
    }

    public String get(String key) {
        try {
            ContentVersion cv = [SELECT VersionData FROM ContentVersion WHERE Id = :key LIMIT 1];
            return cv == null ? null : cv.VersionData.toString();
        } catch (Exception e) {
            return null;
        }
    }

    public void remove(String key) {
        try {
            delete (Id) key;
        } catch (Exception e) {
        }
    }

    public Integer size(String key) {
        try {
            ContentVersion cv = [SELECT ContentSize FROM ContentVersion WHERE Id = :key LIMIT 1];
            return cv == null ? 0 : Integer.valueOf(cv.ContentSize);
        } catch (Exception e) {
            return 0;
        }
    }
}

