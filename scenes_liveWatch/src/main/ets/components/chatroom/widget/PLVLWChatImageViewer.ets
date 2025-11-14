import {
  PLVChatImgEvent,
  PLVChatPlaybackDataVO,
  PLVCommonConstants,
  PLVEmotionEvent,
  PLVHistoryChatImgEvent,
  PLVImageBean,
  PLVLiveSceneSDK,
  PLVTAnswerEvent
} from '@polyvharmony/live-scenes-sdk';
import { CustomDialogPayload, extendNumber, lateInit } from '@polyvharmony/media-player-sdk';

const IMAGE_VIEWER_MAX_SCALE = 5
const IMAGE_VIEWER_MIN_SCALE = 0.5

@Builder
export function PLVLWChatImageViewerBuilder(payload: CustomDialogPayload<PLVLWChatImageViewerPayload>) {
  PLVLWChatImageViewer({
    payload: payload
  })
}

type ImageMessageType = PLVChatImgEvent | PLVHistoryChatImgEvent | PLVEmotionEvent | PLVTAnswerEvent | PLVChatPlaybackDataVO

export class PLVLWChatImageViewerPayload {
  sdk: PLVLiveSceneSDK
  message: ImageMessageType

  constructor(
    sdk: PLVLiveSceneSDK,
    message: ImageMessageType
  ) {
    this.sdk = sdk
    this.message = message
  }
}

@Component
struct PLVLWChatImageViewer {
  payload: CustomDialogPayload<PLVLWChatImageViewerPayload> = lateInit()
  @State private imageUrl: ResourceStr | undefined = undefined
  @State private scaleValue: number = 1
  @State private translateX: number = 0
  @State private translateY: number = 0
  private lastScaleValue: number = 1
  private lastTranslateX: number = 0
  private lastTranslateY: number = 0

  aboutToAppear(): void {
    const message = this.payload.param?.message
    if (message instanceof PLVChatImgEvent) {
      this.imageUrl = message.values?.[0]?.uploadImgUrl
    } else if (message instanceof PLVHistoryChatImgEvent) {
      this.imageUrl = message.content?.uploadImgUrl
    } else if (message instanceof PLVEmotionEvent) {
      this.imageUrl = PLVImageBean.toImageBeanForEmotion(message, this.payload.param?.sdk.chatroomManager.emotions).url
    } else if (message instanceof PLVTAnswerEvent && message.isImgType()) {
      this.imageUrl = message.image?.url
    } else if (message instanceof PLVChatPlaybackDataVO && message.isImgMsgType()) {
      this.imageUrl = message.chatImgContent?.uploadImgUrl
    }
  }

  build() {
    Stack() {
      Image(this.imageUrl)
        .width(PLVCommonConstants.FULL_PERCENT)
        .height(PLVCommonConstants.FULL_PERCENT)
        .objectFit(ImageFit.Contain)
        .scale({
          x: this.scaleValue,
          y: this.scaleValue
        })
        .translate({
          x: this.translateX,
          y: this.translateY
        })
        .hitTestBehavior(HitTestMode.None)
    }
    .width(PLVCommonConstants.FULL_PERCENT)
    .height(PLVCommonConstants.FULL_PERCENT)
    .backgroundColor('#1A1B1F')
    .onClick(() => {
      this.payload.dialog.close()
    })
    .gesture(GestureGroup(GestureMode.Exclusive,
      PinchGesture({ fingers: 2 })
        .onActionStart(() => {
          this.lastScaleValue = this.scaleValue
        })
        .onActionUpdate((event: PinchGestureEvent) => {
          this.scaleValue = extendNumber(this.lastScaleValue * event.scale)
            .coerceIn_ext(IMAGE_VIEWER_MIN_SCALE, IMAGE_VIEWER_MAX_SCALE)
        }),
      PanGesture()
        .onActionStart(() => {
          this.lastTranslateX = this.translateX
          this.lastTranslateY = this.translateY
        })
        .onActionUpdate((event: GestureEvent) => {
          this.translateX = this.lastTranslateX + event.offsetX
          this.translateY = this.lastTranslateY + event.offsetY
        })
    ))
  }
}