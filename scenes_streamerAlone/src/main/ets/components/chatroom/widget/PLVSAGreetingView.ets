import { PLVCommonConstants, PLVJSONUtils, PLVLiveSceneSDK, PLVLoginEvent, PLVSocketOnEvent } from '@polyvharmony/live-scenes-sdk'

const TAG = '[PLVSAGreetingView]'

@Preview
@Component
export struct PLVSAGreetingView {
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined
  @State welcomeTips?: string | Resource = undefined
  @State layoutWidthTranslateX: number = 0
  appearTimerId?: number
  loginListSize: number = 0
  loginNickList: string[] = []

  aboutToAppear(): void {
    this.onChatData()
  }

  build() {
    if (this.welcomeTips) {
      Text(this.welcomeTips)
        .translate({ x: 268 * this.layoutWidthTranslateX - 268 })
        .width(268)
        .height(22)
        .onAppear(() => {
          animateTo({ duration: 500, curve: Curve.Linear }, () => {
            this.layoutWidthTranslateX = 1
          })
          this.appearTimerId = setTimeout(() => {
            animateTo({
              duration: 250, curve: Curve.Linear, onFinish: () => {
                this.welcomeTips = undefined
              }
            }, () => {
              this.layoutWidthTranslateX = 0
            })
          }, 2500)
        })
        .onDisAppear(() => {
          this.layoutWidthTranslateX = 0
          clearTimeout(this.appearTimerId)
          setTimeout(() => {
            this.buildNextWelcomeTips()
          }, PLVCommonConstants.DELAY_TIME_S)
        })
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .fontSize(14)
        .padding({ left: 16, right: 3 })
        .fontColor('#ffffff')
        .backgroundImage($r('app.media.plvsa_greet_bg'))
        .backgroundImageSize(ImageSize.Cover)
    }
  }

  onChatData() {
    this.sdk?.chatroomManager.onData(PLVSocketOnEvent.MESSAGE, (data: string, event: string) => {
      switch (event) {
      // 登录
        case PLVLoginEvent.EVENT:
          const loginEvent = PLVJSONUtils.toFillData(PLVLoginEvent, data)
          if (loginEvent) {
            this.buildWelcomeTips(loginEvent)
          }
          break;
        default:
          break;
      }
    }, this)
  }

  buildWelcomeTips(loginEvent: PLVLoginEvent) {
    this.loginListSize++
    if (this.loginNickList.length < 100) {
      this.loginNickList.push(loginEvent.user?.nick || '')
    }
    this.buildNextWelcomeTips()
  }

  buildNextWelcomeTips() {
    if (this.welcomeTips === undefined) {
      if (this.loginListSize >= 10) {
        this.loginNickList.length = 2
        this.welcomeTips = $r('app.string.plvsa_chat_welcome_join_multi', this.loginNickList.join('、'), this.loginListSize + '')
        this.loginNickList.length = 0
        this.loginListSize = 0
      } else if (this.loginNickList.length >= 1) {
        this.welcomeTips = $r('app.string.plvsa_chat_welcome_join', this.loginNickList.shift())
        this.loginListSize--
      }
    }
  }
}