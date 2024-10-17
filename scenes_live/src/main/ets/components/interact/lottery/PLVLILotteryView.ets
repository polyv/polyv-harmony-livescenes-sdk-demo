import { FunctionBean, PLVCommonConstants, PLVLiveSceneSDK, PLVTimeUtils, PLVWebviewUpdateAppStatusVO } from '@polyvharmony/live-scenes-sdk'

const EVENT_CLICK_LOTTERY_PENDANT = "CLICK_LOTTERY_PENDANT"
const EVENT_UPDATE_IAR_PENDANT = "UPDATE_IAR_PENDANT"
const STATUS_OVER = "over"
const STATUS_RUNNING = "running"
const STATUS_DELAYTIME = "delayTime"

@Component
export struct PLVLILotteryView {
  // <editor-fold defaultstate="collapsed" desc="变量">
  @LocalStorageLink('sdk') sdk?: PLVLiveSceneSDK = undefined

  @State colors: Array<[ResourceColor, number]> = [["#FF9D4D", 0.0], ["#F65F49", 0.5]]
  @State tipsText: string | Resource = ""
  @State cdText: string | Resource = ""

  @State lotteryShow: boolean = false
  @State lotteryCdShow: boolean = false
  @State lotteryTipsShow: boolean = false
  @State lotteryImage: string | Resource = $r('app.media.plvli_interact_lottery')

  @State lotteryWidth: number = 0
  @State lotteryHeight: number = 0
  @State cdTextHeight: number = 0
  @State cdTextWidth: number = 0
  @State tipsWidth: number = 0

  private lotteryVo: FunctionBean | undefined
  private remainTime: number = -1
  private lotteryStatus: string = ""
  private showTipsTaskId?: number
  private lotteryLookCountdownTaskId?: number
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="View内容">

  aboutToAppear(): void {
    this.observer()
  }

  build() {
    RelativeContainer() {
      if (this.lotteryShow) {
        Column() {
          Image(this.lotteryImage)
            .width(34)
            .height(34)
            .onAreaChange((oldValue: Area, newValue: Area) => {
              this.lotteryWidth = newValue.width as number
              this.lotteryHeight = newValue.height as number
            })

          if (this.lotteryCdShow) {
            Text(this.cdText)
              .fontSize(8)
              .fontColor("#FFFFFF")
              .onAreaChange((oldValue: Area, newValue: Area) => {
                this.cdTextWidth = newValue.width as number
                this.cdTextHeight = newValue.height as number
              })
          }
        }
        .onClick((event) => {
          this.onClickLottery()
        })
        .alignItems(HorizontalAlign.Center)
        .alignRules({
          top: { anchor: PLVCommonConstants.CONTAINER, align: VerticalAlign.Top },
          right: { anchor: PLVCommonConstants.CONTAINER, align: HorizontalAlign.End }
        })
        .id('lottery_img')
      }

      if (this.lotteryTipsShow) {
        Row() {
          Text(this.tipsText)
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
          right: { anchor: "lottery_img", align: HorizontalAlign.Start },
          top: { anchor: "lottery_img", align: VerticalAlign.Center }
        })
        .onAreaChange((oldValue: Area, newValue: Area) => {
          this.tipsWidth = newValue.width as number
        })
        .offset({ x: -10, y: -10 })
        .id("lottery_tips_tv")

        Polygon({ width: 10, height: 10 })
          .points([[0, 0], [0, 8], [4, 4]])
          .fill("#F65F49")
          .alignRules({
            left: { anchor: "lottery_tips_tv", align: HorizontalAlign.End },
            top: { anchor: "lottery_tips_tv", align: VerticalAlign.Center }
          })
          .offset({ y: -15, x: -10 })
      }

    }
    .height(this.lotteryShow ? this.lotteryHeight + this.cdTextHeight : 0)
    .width(this.lotteryShow ? this.tipsWidth + this.lotteryWidth : 0)
  }
  // </editor-fold>

  // <editor-fold defaultstate="collapsed" desc="数据订阅">
  observer() {
    this.sdk?.interactManager.interactStatusNotify.on("interact_status", (data: PLVWebviewUpdateAppStatusVO) => {
      if (data.event === EVENT_UPDATE_IAR_PENDANT) {
        if (!data.value || data.value.dataArray?.length == 0) {
          this.hide()
        }
        data.value?.dataArray?.forEach((functionBean) => {
          if (functionBean.event === EVENT_CLICK_LOTTERY_PENDANT) {
            this.lotteryVo = functionBean
            this.parseLotteryMessage(this.lotteryVo)
          }
        })
      }
    })
  }
  // </editor-fold>


  // <editor-fold defaultstate="collapsed" desc="内部方法">
  parseLotteryMessage(lotteryVo: FunctionBean | undefined) {
    if (lotteryVo?.delayTime) {
      this.remainTime = lotteryVo.delayTime != 0 ? lotteryVo?.delayTime : -1
    } else {
      this.remainTime = -1
    }
    this.lotteryStatus = lotteryVo?.status ?? ""
    if (!lotteryVo?.isShow) {
      this.hide()
      return
    }
    //加载自定义的URL图片
    this.lotteryImage = lotteryVo.icon ?? $r('app.media.plvli_interact_lottery')
    if (lotteryVo.status === STATUS_OVER) {
      this.disposeLotteryTask()
      this.disposeShowTipsTask()
      this.lotteryCdShow = true
      this.lotteryShow = true
      this.lotteryTipsShow = false
      return
    }

    if (this.remainTime != -1) {
      this.startLotteryLookCountDownTask(this.remainTime)
    } else {
      this.startLotteryNoCountDown()
    }
    this.show()
  }

  show() {
    this.lotteryShow = true
    this.lotteryCdShow = true
  }

  hide() {
    this.lotteryShow = false
    this.lotteryCdShow = false
    this.lotteryTipsShow = false
  }

  startLotteryLookCountDownTask(needLookTime: number) {
    if (this.lotteryStatus !== STATUS_DELAYTIME) {
      return
    }
    this.disposeLotteryTask()
    this.lotteryLookCountdownTaskId = setInterval(() => {
      needLookTime -= 1
      this.remainTime = needLookTime

      //设置倒数时间
      this.cdText = PLVTimeUtils.generateTime(this.remainTime * 1000, true)

      //设置tips文案 大于3s的显示 '抽奖暂未开始' 小于3s显示'抽奖即将开始'
      if (this.remainTime > 3) {
        this.tipsText = $r("app.string.plvli_lottery_no_start")
      }

      if (this.remainTime <= 3 && this.remainTime > 0) {
        this.tipsText = $r("app.string.plvli_lottery_will_start")
        this.showTipsTask()
      }

      if (needLookTime <= 0) {
        this.cdText = $r("app.string.plvli_lottery_running")
        this.lotteryTipsShow = false
        clearInterval(this.lotteryLookCountdownTaskId)
      }

    }, 1000)
  }

  startLotteryNoCountDown() {
    this.disposeLotteryTask()
    this.disposeShowTipsTask()
    switch (this.lotteryStatus) {
      case STATUS_RUNNING:
        this.lotteryShow = true
        this.tipsText = $r("app.string.plvli_lottery_will_start")
        this.cdText = $r("app.string.plvli_lottery_running")
        break
      case STATUS_OVER:
        this.cdText = $r("app.string.plvli_lottery_over")
        this.lotteryCdShow = true
        break
      default :
        this.lotteryTipsShow = false
    }
  }

  showTipsTask() {
    this.disposeShowTipsTask()
    this.lotteryTipsShow = true
    this.showTipsTaskId = setTimeout(() => {
      this.lotteryTipsShow = false
    }, 3000)
  }

  disposeLotteryTask() {
    clearInterval(this.lotteryLookCountdownTaskId)
  }

  disposeShowTipsTask() {
    clearTimeout(this.showTipsTaskId)
  }

  onClickLottery() {
    if (this.lotteryStatus === "") {
      return
    }

    if (this.lotteryStatus === STATUS_OVER || this.lotteryStatus === STATUS_RUNNING) {
      //这里有两种抽奖情况
      // 一种是即时抽奖，即时抽奖的状态为running，时间为0
      //一种是定时抽奖 定时抽奖有 状态有 delayTime、running、over 时间可以为0也可以不为0
      this.sdk?.interactManager.showLottery()
    } else {
      this.showTipsTask()
    }
  }

  // </editor-fold>


}