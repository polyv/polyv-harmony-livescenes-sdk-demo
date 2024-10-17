import { PLVCommonConstants, PLVDelayRedpackVO, PLVLiveSceneSDK, PLVTimeUtils } from '@polyvharmony/live-scenes-sdk'

@Component
@Preview
export struct PLVLIRedpackView {

  // <editor-fold defaultstate="collapsed" desc="变量">
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined

  @State isShow: boolean = false
  @State redpackTipsShow: boolean = false
  @State colors: Array<[ResourceColor, number]> = [["#FF9D4D", 0.0], ["#F65F49", 0.5]]
  @State tipsWidth: number = 0
  @State redpackWidth: number = 0
  @State redpackHeight: number = 0

  @State redpackCdHeight: number = 0
  @State cdText: string | Resource = ""

  tipsCountDownTaskId?: number
  cdCountDownTaskId?: number
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="View内容">

  aboutToAppear(): void {
    this.observer()
  }

  build() {
    if (this.isShow) {
      RelativeContainer() {
        Column() {
          Image($r('app.media.plvli_red_pack_password_icon'))
            .onAreaChange((oldValue: Area, newValue: Area) => {
              this.redpackWidth = newValue.width as number
              this.redpackHeight = newValue.height as number
            })
            .width(48)
            .height(48)

          Column() {
            Text(this.cdText)
              .fontSize(12)
              .fontColor("#FFFFFF")
          }
          .onAreaChange((oldValue: Area, newValue: Area) => {
            this.redpackCdHeight = newValue.height as number
          })
          .padding({
            left: 3,
            right: 3,
            top: 1,
            bottom: 1
          })
          .borderRadius(8)
          .justifyContent(FlexAlign.Center)
          .backgroundColor("#CC202127")
        }
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .onClick((event) => {
          this.showRedpackTips()
        })
        .id("redpack_img")

        if (this.redpackTipsShow) {
          Row() {
            Text($r('app.string.plv_red_paper_red_pack_hint'))
              .fontSize(13)
              .fontColor("#FFFFFF")
          }
          .borderRadius(4)
          .padding({
            left: 4,
            right: 4,
            top: 3,
            bottom: 3
          })
          .linearGradient({
            direction: GradientDirection.Right,
            colors: this.colors
          })
          .alignRules({
            right: { anchor: "redpack_img", align: HorizontalAlign.Start },
            top: { anchor: "redpack_img", align: VerticalAlign.Center }
          })
          .onAreaChange((oldValue: Area, newValue: Area) => {
            this.tipsWidth = newValue.width as number
          })
          .offset({ x: -10, y: -10 })
          .id("redpack_tips_tv")

          Polygon({ width: 10, height: 10 })
            .points([[0, 0], [0, 8], [4, 4]])
            .fill("#F65F49")
            .alignRules({
              left: { anchor: "redpack_tips_tv", align: HorizontalAlign.End },
              top: { anchor: "redpack_tips_tv", align: VerticalAlign.Center }
            })
            .offset({ y: -15, x: -10 })
        }

      }
      .height(this.redpackHeight + this.redpackCdHeight)
      .width(this.redpackWidth + this.tipsWidth)

    }
  }
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="订阅数据">
  observer() {
    this.sdk?.redpackManager.eventDataNotify.on('redpack_data', (delayRedpack: PLVDelayRedpackVO) => {
      if (delayRedpack.redpackSendTime === 0) {
        return
      }
      // 倒数时间处理
      const cdTime = delayRedpack.redpackSendTime ?? 0
      if (cdTime <= Date.now()) {
        this.stop()
        return
      }

      this.start(cdTime - Date.now())
    })
  }

  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="内部方法">

  private showRedpackTips() {
    clearTimeout(this.tipsCountDownTaskId)
    this.redpackTipsShow = true
    this.tipsCountDownTaskId = setTimeout(() => {
      this.redpackTipsShow = false
    }, 3000)
  }

  private start(delay: number) {
    this.stop()
    this.cdCountDownTaskId = setInterval(() => {
      delay -= 1000
      this.isShow = true
      this.cdText = PLVTimeUtils.generateTime(delay, false)
      if (delay <= 0) {
        this.isShow = false
        clearInterval(this.cdCountDownTaskId)
      }
    }, 1000)
  }

  private stop() {
    clearInterval(this.cdCountDownTaskId)
    this.isShow = false
  }
  // </editor-fold>

}