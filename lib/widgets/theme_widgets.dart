import 'package:flutter/material.dart';

/// Card no estilo escuro do layout (fundo #232D37, bordas 8px).
class ThemeCard extends StatelessWidget {
  const ThemeCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF232D37),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

/// Título de card no estilo teal.
class _TituloCardInterno extends StatelessWidget {
  const _TituloCardInterno(this.texto, {this.icone});

  final String texto;
  final String? icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icone != null) ...[
          ImageIcon(
            AssetImage(icone!),
            size: 20,
            color: const Color(0xFF1FB196),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          texto,
          style: const TextStyle(
            color: Color(0xFF1FB196),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TituloCard extends StatelessWidget {
  const TituloCard(this.texto, {super.key, this.icone});

  final String texto;
  final String? icone;

  @override
  Widget build(BuildContext context) => _TituloCardInterno(texto, icone: icone);
}

/// Botão teal compacto (ex.: "SELECIONAR").
class BotaoTeal extends StatelessWidget {
  const BotaoTeal({
    super.key,
    required this.rotulo,
    this.onPressed,
  });

  final String rotulo;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFF139F86),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
      child: Text(rotulo),
    );
  }
}

/// Botão principal (largura total, teal, uppercase).
class BotaoPrincipal extends StatelessWidget {
  const BotaoPrincipal({
    super.key,
    required this.rotulo,
    this.onPressed,
  });

  final String rotulo;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF139F86),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
        disabledBackgroundColor: const Color(0xFF0F836E),
      ),
      child: Text(rotulo),
    );
  }
}

/// Subtexto (cinza claro).
class Subtexto extends StatelessWidget {
  const Subtexto(this.texto, {super.key, this.tamanho = 13, this.textoCentralizado = false});

  final String texto;
  final double tamanho;
  final bool textoCentralizado;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      textAlign: textoCentralizado ? TextAlign.center : TextAlign.start,
      style: TextStyle(color: const Color(0xFF8E9BA8), fontSize: tamanho),
    );
  }
}

/// Card com cabeçalho (título + botão) e conteúdo.
class CardComCabecalho extends StatelessWidget {
  const CardComCabecalho({
    super.key,
    required this.titulo,
    required this.acoes,
    required this.conteudo,
    this.icone,
  });

  final String titulo;
  final String? icone;
  final List<Widget> acoes;
  final Widget conteudo;

  @override
  Widget build(BuildContext context) {
    return ThemeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: TituloCard(titulo, icone: icone)),
              ...acoes,
            ],
          ),
          const SizedBox(height: 8),
          conteudo,
        ],
      ),
    );
  }
}

/// Card de seleção de arquivo (título + botão + texto do arquivo).
class CardArquivoEntrada extends StatelessWidget {
  const CardArquivoEntrada({
    super.key,
    required this.titulo,
    required this.botao,
    required this.texto,
    required this.onBotao,
    this.icone,
    this.subtitulo,
    this.acoesExtras = const [],
  });

  final String titulo;
  final String? icone;
  final String botao;
  final String texto;
  final String? subtitulo;
  final VoidCallback onBotao;
  final List<Widget> acoesExtras;

  @override
  Widget build(BuildContext context) {
    return ThemeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: TituloCard(titulo, icone: icone)),
              if (acoesExtras.isNotEmpty) ...[...acoesExtras, const SizedBox(width: 6)],
              BotaoTeal(rotulo: botao, onPressed: onBotao),
            ],
          ),
          const SizedBox(height: 8),
          if (subtitulo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Subtexto(subtitulo!, tamanho: 11),
            ),
          Subtexto(texto),
        ],
      ),
    );
  }
}

/// Linha "rótulo + campo de texto" no estilo do layout (borda inferior).
class CampoLinha extends StatelessWidget {
  const CampoLinha({
    super.key,
    required this.rotulo,
    required this.controller,
    this.centralizado = false,
    this.keyboardType,
    this.expandir = false,
  });

  final String rotulo;
  final TextEditingController controller;
  final bool centralizado;
  final bool expandir;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final campo = TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: centralizado ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Digite...',
        hintStyle: TextStyle(color: Color(0xFF6B7C93)),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4A5568)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF4A5568)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1FB196)),
        ),
      ),
    );

    if (expandir) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 80, child: Subtexto(rotulo)),
            const SizedBox(width: 8),
            Expanded(child: campo),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(flex: 2, child: Subtexto(rotulo)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: campo),
        ],
      ),
    );
  }
}

/// Opção de rádio no estilo do layout.
class OpcaoRadio extends StatelessWidget {
  const OpcaoRadio({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.onChanged,
  });

  final String rotulo;
  final bool valor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!valor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<bool>(
            value: true,
            groupValue: valor ? true : null,
            activeColor: const Color(0xFF1FB196),
            onChanged: (_) => onChanged(true),
          ),
          Text(
            rotulo,
            style: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 13),
          ),
        ],
      ),
    );
  }
}