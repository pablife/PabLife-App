import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const String route = '/politica-de-privacidade';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        title: const Text(
          'Politica de Privacidade',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Politica de Privacidade',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildParagraph(
                  'A sua privacidade e importante para nos. E politica do Pablife respeitar a sua privacidade em relacao a qualquer informacao sua que possamos coletar no site Pablife, e outros sites que possuimos e operamos.',
                ),
                _buildParagraph(
                  'Solicitamos informacoes pessoais apenas quando realmente precisamos delas para lhe fornecer um servico. Fazemo-lo por meios justos e legais, com o seu conhecimento e consentimento. Tambem informamos por que estamos coletando e como sera usado.',
                ),
                _buildParagraph(
                  'Apenas retemos as informacoes coletadas pelo tempo necessario para fornecer o servico solicitado. Quando armazenamos dados, protegemos dentro de meios comercialmente aceitaveis para evitar perdas e roubos, bem como acesso, divulgacao, copia, uso ou modificacao nao autorizados.',
                ),
                _buildParagraph(
                  'Nao compartilhamos informacoes de identificacao pessoal publicamente ou com terceiros, exceto quando exigido por lei.',
                ),
                _buildParagraph(
                  'O nosso site pode ter links para sites externos que nao sao operados por nos. Esteja ciente de que nao temos controle sobre o conteudo e praticas desses sites e nao podemos aceitar responsabilidade por suas respectivas politicas de privacidade.',
                ),
                _buildParagraph(
                  'Voce e livre para recusar a nossa solicitacao de informacoes pessoais, entendendo que talvez nao possamos fornecer alguns dos servicos desejados.',
                ),
                _buildParagraph(
                  'O uso continuado de nosso site sera considerado como aceitacao de nossas praticas em torno de privacidade e informacoes pessoais. Se voce tiver alguma duvida sobre como lidamos com dados do usuario e informacoes pessoais, entre em contato conosco.',
                ),
                const SizedBox(height: 24),
                _buildParagraph(
                  'O servico Google AdSense que usamos para veicular publicidade usa um cookie DoubleClick para veicular anuncios mais relevantes em toda a Web e limitar o numero de vezes que um determinado anuncio e exibido para voce.',
                ),
                _buildParagraph(
                  'Para mais informacoes sobre o Google AdSense, consulte as FAQs oficiais sobre privacidade do Google AdSense.',
                ),
                _buildParagraph(
                  'Utilizamos anuncios para compensar os custos de funcionamento deste site e fornecer financiamento para futuros desenvolvimentos. Os cookies de publicidade comportamental usados por este site foram projetados para garantir que voce forneca os anuncios mais relevantes sempre que possivel, rastreando anonimamente seus interesses e apresentando coisas semelhantes que possam ser do seu interesse.',
                ),
                _buildParagraph(
                  'Varios parceiros anunciam em nosso nome e os cookies de rastreamento de afiliados simplesmente nos permitem ver se nossos clientes acessaram o site atraves de um dos sites de nossos parceiros, para que possamos credita-los adequadamente e, quando aplicavel, permitir que nossos parceiros afiliados oferecam qualquer promocao que pode fornece-lo para fazer uma compra.',
                ),
                const SizedBox(height: 24),
                _buildSection('Compromisso do Usuario'),
                _buildParagraph(
                  'O usuario se compromete a fazer uso adequado dos conteudos e da informacao que o Pablife oferece no site e com carater enunciativo, mas nao limitativo:',
                ),
                _buildListItem(
                  'A) Nao se envolver em atividades que sejam ilegais ou contrarias a boa fe e a ordem publica;',
                ),
                _buildListItem(
                  'B) Nao difundir propaganda ou conteudo de natureza racista, xenofobica, jogos de azar, qualquer tipo de pornografia ilegal, de apologia ao terrorismo ou contra os direitos humanos;',
                ),
                _buildListItem(
                  'C) Nao causar danos aos sistemas fisicos (hardwares) e logicos (softwares) do Pablife, de seus fornecedores ou terceiros, para introduzir ou disseminar virus informaticos ou quaisquer outros sistemas de hardware ou software que sejam capazes de causar danos anteriormente mencionados.',
                ),
                const SizedBox(height: 24),
                _buildSection('Mais informacoes'),
                _buildParagraph(
                  'Esperamos que esteja esclarecido e, como mencionado anteriormente, se houver algo que voce nao tem certeza se precisa ou nao, geralmente e mais seguro deixar os cookies ativados, caso interaja com um dos recursos que voce usa em nosso site.',
                ),
                const SizedBox(height: 24),
                Text(
                  'Esta politica e efetiva a partir de 27 de Novembro de 2025',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    '© ${DateTime.now().year} Pablife. Todos os direitos reservados.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E3A5F),
        ),
      ),
    );
  }

  Widget _buildParagraph(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildListItem(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16),
      child: Text(
        content,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }
}
