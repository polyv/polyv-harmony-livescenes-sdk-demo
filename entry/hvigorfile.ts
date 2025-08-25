import { hapTasks, OhosHapContext, OhosPluginId } from '@ohos/hvigor-ohos-plugin';
import { hvigor, getNode } from '@ohos/hvigor'
import fs from 'fs';

function readProperties(filePath) {
    const result = {}
    try {
        fs.accessSync(filePath)
    } catch (e) {
        console.error(e)
        return result
    }
    const raw = fs.readFileSync(filePath, 'utf-8')
    raw.split('\n')
        .filter(line => !line.startsWith('#') && line.trim().length !== 0)
        .forEach(line => {
            const kv = line.split('=')
            result[kv[0]] = kv[1]
        })
    return result
}

// 读取项目 local.properties 配置的登录参数，设置进 build-profile
getNode(__filename).afterNodeEvaluate(node => {
    const hapContext = node.getContext(OhosPluginId.OHOS_HAP_PLUGIN) as OhosHapContext;
    const buildProfile = hapContext.getBuildProfileOpt();

    const localProperties = readProperties(`${__dirname}/../local.properties`)
    if (!buildProfile.buildOption) {
        buildProfile.buildOption = {}
    }
    if (!buildProfile.buildOption.arkOptions) {
        buildProfile.buildOption.arkOptions = {}
    }
    if (!buildProfile.buildOption.arkOptions.buildProfileFields) {
        buildProfile.buildOption.arkOptions.buildProfileFields = {}
    }
    for (const key in localProperties) {
        const newKey = `property_${key.replaceAll(/\./g, "_")}`
        buildProfile.buildOption.arkOptions.buildProfileFields[newKey] = localProperties[key]
    }

    hapContext.setBuildProfileOpt(buildProfile);
})

export default {
    system: hapTasks,  /* Built-in plugin of Hvigor. It cannot be modified. */
    plugins:[]         /* Custom plugin to extend the functionality of Hvigor. */
}
