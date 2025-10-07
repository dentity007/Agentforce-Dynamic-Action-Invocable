public with sharing class InvocableActionFactory {
    public interface IAction {
        PlanModels.OrchestratorResult execute(Map<String, Object> input);
    }

    private static Map<String, String> overrides = new Map<String, String>();

    public static void register(String actionName, String className) {
        if (String.isBlank(actionName) || String.isBlank(className)) {
            return;
        }
        overrides.put(actionName, className);
    }

    public static void clear() {
        overrides.clear();
    }

    public static IAction resolve(String actionName) {
        if (String.isBlank(actionName)) {
            throw new AuraHandledException('Action name is required.');
        }
        String implName = overrides.containsKey(actionName)
            ? overrides.get(actionName)
            : deriveDynamicClassName(actionName);
        Type actionType = Type.forName(implName);
        if (actionType == null) {
            throw new AuraHandledException('Generated action class not found: ' + implName);
        }
        Object instance = actionType.newInstance();
        if (!(instance instanceof InvocableActionFactory.IAction)) {
            throw new AuraHandledException('Class ' + implName + ' does not implement IAction.');
        }
        return (InvocableActionFactory.IAction) instance;
    }

    private static String deriveDynamicClassName(String actionName) {
        String cleaned = actionName.replaceAll('[^A-Za-z0-9_]', '_');
        if (String.isBlank(cleaned)) {
            cleaned = 'GeneratedAction';
        }
        if (!Pattern.matches('^[A-Za-z].*', cleaned)) {
            cleaned = 'A' + cleaned;
        }
        return 'DynamicAction_' + cleaned;
    }
}
