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
        LoginLiveEcommerceEntry()
        LoginLiveWatchEntry()
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
struct LoginLiveEcommerceEntry {
  build() {
    Stack() {
      Image($r('app.media.plv_entrance_live_bg'))
      Text() {
        Span('直播带货\n')
        Span('(废弃，不再新增功能)')
          .fontSize(16)
      }
      .fontColor('#FFFFFF')
      .fontSize(24)
      .margin(36)
    }
    .alignContent(Alignment.TopStart)
    .width(244)
    .height(140)
    .onClick(() => {
      router.pushUrl({
        url: "pages/PLVLoginPage",
        params: { 'newLiveWatch': false }
      })
    })
  }
}

@Component
struct LoginLiveWatchEntry {
  build() {
    Stack() {
      Image($r('app.media.plv_entrance_live_bg'))
      Text() {
        Span('云直播观看\n')
        Span('(推荐)')
          .fontSize(16)
      }
      .fontColor('#FFFFFF')
      .fontSize(24)
      .margin(36)
    }
    .alignContent(Alignment.TopStart)
    .width(244)
    .height(140)
    .onClick(() => {
      router.pushUrl({
        url: "pages/PLVLoginPage",
        params: { 'newLiveWatch': true }
      })
    })
  }
}