import {
  BaseDanmaku,
  BaseDanmakuParser,
  Callback,
  DanmakuContext,
  Danmakus,
  DanmakuTimer,
  DanmakuView,
  IDanmakus
} from '@ohos/danmakuflamemaster';
import {
  PLVCommonConstants,
  PLVJSONUtils,
  PLVLiveSceneSDK,
  PLVLocalSpeakEvent,
  PLVLogger,
  PLVSocketOnEvent,
  PLVSpeakEvent
} from '@polyvharmony/live-scenes-sdk';
import { lateInit, MutableObserver, runCatching, watchStates } from '@polyvharmony/media-player-sdk';
import { PLVLWLayoutDataBus } from '../../../common/PLVLWLayoutDataBus';

const TAG = 'PLVLWDanmuLayout'

@Component
export struct PLVLWDanmuLayout {
  @LocalStorageLink('sdk') sdk: PLVLiveSceneSDK = lateInit()
  @Consume('layoutDataBus') layoutDataBus: PLVLWLayoutDataBus
  @State private readonly danmuModel: DanmakuView.Model = new DanmakuView.Model()
  @State private isVisible: boolean = false
  private observers: MutableObserver[] = []

  aboutToAppear(): void {
    this.observeChatMessage()
    watchStates(() => {
      const isPortrait = this.layoutDataBus.isPortrait.value
      const playerFullscreen = this.layoutDataBus.playerFullscreen.value
      const danmuSetting = this.layoutDataBus.danmuSetting.value
      this.isVisible = (danmuSetting?.show ?? false) && !(isPortrait && playerFullscreen)
    }).pushTo(this.observers)
  }

  build() {
    Stack() {
      DanmakuView({
        model: this.danmuModel
      })
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .visibility(this.isVisible ? Visibility.Visible : Visibility.None)
    .onAppear(() => {
      this.prepareDanmuModel()
    })
    .onAreaChange((oldArea, newArea) => {
      catchingError(() => {
        this.danmuModel.setWidth(vp2px(newArea.width as number))
        this.danmuModel.setHeight(vp2px(newArea.height as number))
      })
    })
  }

  private prepareDanmuModel() {
    const danmuModel = this.danmuModel;

    class DanmakuCallback implements Callback {
      prepared(): void {
        catchingError(() => {
          danmuModel.start()
        })
      }

      updateTimer(timer: DanmakuTimer): void {
      }

      danmakuShown(danmaku: BaseDanmaku): void {
      }

      drawingFinished(): void {
      }
    }

    class DanmakuParser extends BaseDanmakuParser {
      protected parse(): IDanmakus {
        return new Danmakus({})
      }
    }

    catchingError(() => {
      const maxLinesPair: Map<number, number> = new Map();
      maxLinesPair.set(BaseDanmaku.TYPE_SCROLL_RL, 5);
      const overlappingEnablePair: Map<number, boolean> = new Map();
      overlappingEnablePair.set(BaseDanmaku.TYPE_SCROLL_RL, true);
      const danmuContext = DanmakuContext.create()
        .setDuplicateMergingEnabled(false)
        .setMaximumLines(maxLinesPair)
        .setOverlapping(overlappingEnablePair)
      this.danmuModel.setCallback(new DanmakuCallback())
      this.danmuModel.prepare(new DanmakuParser(), danmuContext)
    })
  }

  private observeChatMessage() {
    this.sdk.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      switch (event) {
        case PLVSpeakEvent.EVENT: {
          const speakEvent = PLVJSONUtils.toFillData(PLVSpeakEvent, data);
          if (speakEvent && !speakEvent.isFileShareEvent()) {
            if (this.sdk.channelData.viewerId !== speakEvent.user?.userId) {
              this.emitDanmu(speakEvent.values?.[0])
            }
          }
          break;
        }
      }
    }, this)
    this.layoutDataBus.onLocalChatEvent.observe((event) => {
      if (event instanceof PLVLocalSpeakEvent) {
        this.emitDanmu(event.speakMessage)
      }
    }).pushTo(this.observers)
  }

  private emitDanmu(text: string | undefined) {
    if (!text) {
      return
    }
    const danmu = this.danmuModel.getConfig().mDanmakuFactory.createDanmaku(BaseDanmaku.TYPE_SCROLL_RL)
    danmu.text = text
    danmu.isLive = true
    danmu.setTime(this.danmuModel.getCurrentTime())
    danmu.priority = 0
    danmu.textSize = fp2px(16)
    danmu.textColor = 0xFFFFFFFF
    danmu.textShadowColor = 0xFF000000
    catchingError(() => {
      this.danmuModel.addDanmaku(danmu)
      if (this.danmuModel['delegate']?.['handler']?.['mRenderingState']?.['nothingRendered'] !== undefined) {
        this.danmuModel['delegate']['handler']['mRenderingState']['nothingRendered'] = false
      }
    })
  }

  aboutToDisappear(): void {
    MutableObserver.disposeAll(this.observers)
  }
}

function catchingError(runnable: () => void) {
  const result = runCatching(runnable)
  if (result.success === false) {
    PLVLogger.error(TAG, result.error.message)
  }
}
