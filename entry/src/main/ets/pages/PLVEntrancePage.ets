import { router } from '@kit.ArkUI'

@Entry
@Component
struct PLVEntrancePage {
  build() {
    Stack() {
      Image($r('app.media.plv_entrance_bg'))
        .objectFit(ImageFit.Cover)
        .expandSafeArea()

      Column() {
        LoginStreamerEntry()
        LoginWatchEntry()
      }
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct LoginStreamerEntry {
  build() {
    Stack() {
      Image($r('app.media.plv_entrance_streamer_bg'))
      Text("手机开播")
        .fontColor('#FFFFFF')
        .fontSize(24)
        .margin(36)
    }
    .alignContent(Alignment.TopStart)
    .width(244)
    .height(140)
    .onClick(() => {
      router.pushUrl({
        url: "pages/PLVLoginStreamerPage"
      })
    })
  }
}

@Component
struct LoginWatchEntry {
  build() {
    Stack() {
      Image($r('app.media.plv_entrance_live_bg'))
      Text("云直播观看")
        .fontColor('#FFFFFF')
        .fontSize(24)
        .margin(36)
    }
    .alignContent(Alignment.TopStart)
    .width(244)
    .height(140)
    .onClick(() => {
      router.pushUrl({
        url: "pages/PLVLoginPage"
      })
    })
  }
}