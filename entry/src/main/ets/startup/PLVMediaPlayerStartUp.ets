import {
  IPLVKVStore,
  Logger,
  PLVKVStore,
  PLVMediaPlayerAppContext,
  PLVMediaPlayerFactory,
  PLVMediaPlayerLogger,
  runCatching
} from '@polyvharmony/media-player-sdk';
import { PLVMediaPlayerCoreIjkProvider } from '@polyvharmony/media-player-core-ijk';
import { Context } from '@ohos.abilityAccessCtrl';
import distributedKVStore from '@ohos.data.distributedKVStore';
import { PLVLogger } from 'scenes_live';

export class PLVMediaPlayerStartUp {
  private static isInit = false

  static start(context: Context) {
    if (PLVMediaPlayerStartUp.isInit) {
      return
    }
    PLVMediaPlayerStartUp.isInit = true

    PLVMediaPlayerAppContext.getInstance().setupAppContext(context)
    PLVMediaPlayerLogger.loggerImpl = new PLVLoggerImpl()
    PLVKVStore.setupImplement(new PLVKVStoreOhosImpl(context))
    PLVMediaPlayerFactory.getInstance().register(PLVMediaPlayerCoreIjkProvider.getInstance())
  }
}

class PLVLoggerImpl implements Logger {
  debug(tag: string, message: string) {
    PLVLogger.debug(tag, message)
  }

  info(tag: string, message: string) {
    PLVLogger.info(tag, message)
  }

  warn(tag: string, message: string) {
    PLVLogger.warn(tag, message)
  }

  error(tag: string, message: string) {
    PLVLogger.error(tag, message)
  }
}

class PLVKVStoreOhosImpl implements IPLVKVStore {
  private static readonly kvStoreId = "PLVKVStoreOhosImpl"

  constructor(context: Context) {
    this.kvStoreManager = distributedKVStore.createKVManager({
      context: context,
      bundleName: context.applicationInfo.name
    })
    this.ensureKvStore()
  }

  private kvStoreManager: distributedKVStore.KVManager | undefined = undefined;
  private kvStore: distributedKVStore.DeviceKVStore | undefined = undefined;

  async getValue(key: string): Promise<string | undefined> {
    if (!this.kvStore) {
      await this.ensureKvStore()
    }

    const result = await runCatching(this.kvStore?.get(key))
    if (result.success) {
      return result.data as string
    } else {
      return undefined
    }
  }

  async setValue(key: string, value: string): Promise<void> {
    await this.ensureKvStore()
    this.kvStore?.put(key, value)
  }

  async delete(key: string): Promise<void> {
    await this.ensureKvStore()
    this.kvStore?.delete(key)
  }

  private async ensureKvStore() {
    this.kvStore = await this.kvStoreManager?.getKVStore(PLVKVStoreOhosImpl.kvStoreId, {
      securityLevel: distributedKVStore.SecurityLevel.S1
    }) as distributedKVStore.DeviceKVStore
  }
}